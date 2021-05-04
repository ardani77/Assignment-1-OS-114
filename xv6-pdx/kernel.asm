
kernel:     file format elf32-i386


Disassembly of section .text:

80100000 <multiboot_header>:
80100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
80100006:	00 00                	add    %al,(%eax)
80100008:	fe 4f 52             	decb   0x52(%edi)
8010000b:	e4                   	.byte 0xe4

8010000c <entry>:

# Entering xv6 on boot processor, with paging off.
.globl entry
entry:
  # Turn on page size extension for 4Mbyte pages
  movl    %cr4, %eax
8010000c:	0f 20 e0             	mov    %cr4,%eax
  orl     $(CR4_PSE), %eax
8010000f:	83 c8 10             	or     $0x10,%eax
  movl    %eax, %cr4
80100012:	0f 22 e0             	mov    %eax,%cr4
  # Set page directory
  movl    $(V2P_WO(entrypgdir)), %eax
80100015:	b8 00 90 10 00       	mov    $0x109000,%eax
  movl    %eax, %cr3
8010001a:	0f 22 d8             	mov    %eax,%cr3
  # Turn on paging.
  movl    %cr0, %eax
8010001d:	0f 20 c0             	mov    %cr0,%eax
  orl     $(CR0_PG|CR0_WP), %eax
80100020:	0d 00 00 01 80       	or     $0x80010000,%eax
  movl    %eax, %cr0
80100025:	0f 22 c0             	mov    %eax,%cr0

  # Set up the stack pointer.
  movl $(stack + KSTACKSIZE), %esp
80100028:	bc 20 d6 10 80       	mov    $0x8010d620,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 52 2b 10 80       	mov    $0x80102b52,%eax
  jmp *%eax
80100032:	ff e0                	jmp    *%eax

80100034 <bget>:
// Look through buffer cache for block on device dev.
// If not found, allocate a buffer.
// In either case, return locked buffer.
static struct buf*
bget(uint dev, uint blockno)
{
80100034:	55                   	push   %ebp
80100035:	89 e5                	mov    %esp,%ebp
80100037:	57                   	push   %edi
80100038:	56                   	push   %esi
80100039:	53                   	push   %ebx
8010003a:	83 ec 18             	sub    $0x18,%esp
8010003d:	89 c6                	mov    %eax,%esi
8010003f:	89 d7                	mov    %edx,%edi
  struct buf *b;

  acquire(&bcache.lock);
80100041:	68 20 d6 10 80       	push   $0x8010d620
80100046:	e8 22 3d 00 00       	call   80103d6d <acquire>

  // Is the block already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
8010004b:	8b 1d 70 1d 11 80    	mov    0x80111d70,%ebx
80100051:	83 c4 10             	add    $0x10,%esp
80100054:	eb 03                	jmp    80100059 <bget+0x25>
80100056:	8b 5b 54             	mov    0x54(%ebx),%ebx
80100059:	81 fb 1c 1d 11 80    	cmp    $0x80111d1c,%ebx
8010005f:	74 30                	je     80100091 <bget+0x5d>
    if(b->dev == dev && b->blockno == blockno){
80100061:	39 73 04             	cmp    %esi,0x4(%ebx)
80100064:	75 f0                	jne    80100056 <bget+0x22>
80100066:	39 7b 08             	cmp    %edi,0x8(%ebx)
80100069:	75 eb                	jne    80100056 <bget+0x22>
      b->refcnt++;
8010006b:	8b 43 4c             	mov    0x4c(%ebx),%eax
8010006e:	83 c0 01             	add    $0x1,%eax
80100071:	89 43 4c             	mov    %eax,0x4c(%ebx)
      release(&bcache.lock);
80100074:	83 ec 0c             	sub    $0xc,%esp
80100077:	68 20 d6 10 80       	push   $0x8010d620
8010007c:	e8 55 3d 00 00       	call   80103dd6 <release>
      acquiresleep(&b->lock);
80100081:	8d 43 0c             	lea    0xc(%ebx),%eax
80100084:	89 04 24             	mov    %eax,(%esp)
80100087:	e8 d4 3a 00 00       	call   80103b60 <acquiresleep>
      return b;
8010008c:	83 c4 10             	add    $0x10,%esp
8010008f:	eb 4c                	jmp    801000dd <bget+0xa9>
  }

  // Not cached; recycle an unused buffer.
  // Even if refcnt==0, B_DIRTY indicates a buffer is in use
  // because log.c has modified it but not yet committed it.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100091:	8b 1d 6c 1d 11 80    	mov    0x80111d6c,%ebx
80100097:	eb 03                	jmp    8010009c <bget+0x68>
80100099:	8b 5b 50             	mov    0x50(%ebx),%ebx
8010009c:	81 fb 1c 1d 11 80    	cmp    $0x80111d1c,%ebx
801000a2:	74 43                	je     801000e7 <bget+0xb3>
    if(b->refcnt == 0 && (b->flags & B_DIRTY) == 0) {
801000a4:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801000a8:	75 ef                	jne    80100099 <bget+0x65>
801000aa:	f6 03 04             	testb  $0x4,(%ebx)
801000ad:	75 ea                	jne    80100099 <bget+0x65>
      b->dev = dev;
801000af:	89 73 04             	mov    %esi,0x4(%ebx)
      b->blockno = blockno;
801000b2:	89 7b 08             	mov    %edi,0x8(%ebx)
      b->flags = 0;
801000b5:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
      b->refcnt = 1;
801000bb:	c7 43 4c 01 00 00 00 	movl   $0x1,0x4c(%ebx)
      release(&bcache.lock);
801000c2:	83 ec 0c             	sub    $0xc,%esp
801000c5:	68 20 d6 10 80       	push   $0x8010d620
801000ca:	e8 07 3d 00 00       	call   80103dd6 <release>
      acquiresleep(&b->lock);
801000cf:	8d 43 0c             	lea    0xc(%ebx),%eax
801000d2:	89 04 24             	mov    %eax,(%esp)
801000d5:	e8 86 3a 00 00       	call   80103b60 <acquiresleep>
      return b;
801000da:	83 c4 10             	add    $0x10,%esp
    }
  }
  panic("bget: no buffers");
}
801000dd:	89 d8                	mov    %ebx,%eax
801000df:	8d 65 f4             	lea    -0xc(%ebp),%esp
801000e2:	5b                   	pop    %ebx
801000e3:	5e                   	pop    %esi
801000e4:	5f                   	pop    %edi
801000e5:	5d                   	pop    %ebp
801000e6:	c3                   	ret    
  panic("bget: no buffers");
801000e7:	83 ec 0c             	sub    $0xc,%esp
801000ea:	68 60 66 10 80       	push   $0x80106660
801000ef:	e8 68 02 00 00       	call   8010035c <panic>

801000f4 <binit>:
{
801000f4:	f3 0f 1e fb          	endbr32 
801000f8:	55                   	push   %ebp
801000f9:	89 e5                	mov    %esp,%ebp
801000fb:	53                   	push   %ebx
801000fc:	83 ec 0c             	sub    $0xc,%esp
  initlock(&bcache.lock, "bcache");
801000ff:	68 71 66 10 80       	push   $0x80106671
80100104:	68 20 d6 10 80       	push   $0x8010d620
80100109:	e8 0f 3b 00 00       	call   80103c1d <initlock>
  bcache.head.prev = &bcache.head;
8010010e:	c7 05 6c 1d 11 80 1c 	movl   $0x80111d1c,0x80111d6c
80100115:	1d 11 80 
  bcache.head.next = &bcache.head;
80100118:	c7 05 70 1d 11 80 1c 	movl   $0x80111d1c,0x80111d70
8010011f:	1d 11 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100122:	83 c4 10             	add    $0x10,%esp
80100125:	bb 54 d6 10 80       	mov    $0x8010d654,%ebx
8010012a:	eb 37                	jmp    80100163 <binit+0x6f>
    b->next = bcache.head.next;
8010012c:	a1 70 1d 11 80       	mov    0x80111d70,%eax
80100131:	89 43 54             	mov    %eax,0x54(%ebx)
    b->prev = &bcache.head;
80100134:	c7 43 50 1c 1d 11 80 	movl   $0x80111d1c,0x50(%ebx)
    initsleeplock(&b->lock, "buffer");
8010013b:	83 ec 08             	sub    $0x8,%esp
8010013e:	68 78 66 10 80       	push   $0x80106678
80100143:	8d 43 0c             	lea    0xc(%ebx),%eax
80100146:	50                   	push   %eax
80100147:	e8 dd 39 00 00       	call   80103b29 <initsleeplock>
    bcache.head.next->prev = b;
8010014c:	a1 70 1d 11 80       	mov    0x80111d70,%eax
80100151:	89 58 50             	mov    %ebx,0x50(%eax)
    bcache.head.next = b;
80100154:	89 1d 70 1d 11 80    	mov    %ebx,0x80111d70
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
8010015a:	81 c3 5c 02 00 00    	add    $0x25c,%ebx
80100160:	83 c4 10             	add    $0x10,%esp
80100163:	81 fb 1c 1d 11 80    	cmp    $0x80111d1c,%ebx
80100169:	72 c1                	jb     8010012c <binit+0x38>
}
8010016b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010016e:	c9                   	leave  
8010016f:	c3                   	ret    

80100170 <bread>:

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
80100170:	f3 0f 1e fb          	endbr32 
80100174:	55                   	push   %ebp
80100175:	89 e5                	mov    %esp,%ebp
80100177:	53                   	push   %ebx
80100178:	83 ec 04             	sub    $0x4,%esp
  struct buf *b;

  b = bget(dev, blockno);
8010017b:	8b 55 0c             	mov    0xc(%ebp),%edx
8010017e:	8b 45 08             	mov    0x8(%ebp),%eax
80100181:	e8 ae fe ff ff       	call   80100034 <bget>
80100186:	89 c3                	mov    %eax,%ebx
  if((b->flags & B_VALID) == 0) {
80100188:	f6 00 02             	testb  $0x2,(%eax)
8010018b:	74 07                	je     80100194 <bread+0x24>
    iderw(b);
  }
  return b;
}
8010018d:	89 d8                	mov    %ebx,%eax
8010018f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100192:	c9                   	leave  
80100193:	c3                   	ret    
    iderw(b);
80100194:	83 ec 0c             	sub    $0xc,%esp
80100197:	50                   	push   %eax
80100198:	e8 29 1d 00 00       	call   80101ec6 <iderw>
8010019d:	83 c4 10             	add    $0x10,%esp
  return b;
801001a0:	eb eb                	jmp    8010018d <bread+0x1d>

801001a2 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
801001a2:	f3 0f 1e fb          	endbr32 
801001a6:	55                   	push   %ebp
801001a7:	89 e5                	mov    %esp,%ebp
801001a9:	53                   	push   %ebx
801001aa:	83 ec 10             	sub    $0x10,%esp
801001ad:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holdingsleep(&b->lock))
801001b0:	8d 43 0c             	lea    0xc(%ebx),%eax
801001b3:	50                   	push   %eax
801001b4:	e8 39 3a 00 00       	call   80103bf2 <holdingsleep>
801001b9:	83 c4 10             	add    $0x10,%esp
801001bc:	85 c0                	test   %eax,%eax
801001be:	74 14                	je     801001d4 <bwrite+0x32>
    panic("bwrite");
  b->flags |= B_DIRTY;
801001c0:	83 0b 04             	orl    $0x4,(%ebx)
  iderw(b);
801001c3:	83 ec 0c             	sub    $0xc,%esp
801001c6:	53                   	push   %ebx
801001c7:	e8 fa 1c 00 00       	call   80101ec6 <iderw>
}
801001cc:	83 c4 10             	add    $0x10,%esp
801001cf:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801001d2:	c9                   	leave  
801001d3:	c3                   	ret    
    panic("bwrite");
801001d4:	83 ec 0c             	sub    $0xc,%esp
801001d7:	68 7f 66 10 80       	push   $0x8010667f
801001dc:	e8 7b 01 00 00       	call   8010035c <panic>

801001e1 <brelse>:

// Release a locked buffer.
// Move to the head of the MRU list.
void
brelse(struct buf *b)
{
801001e1:	f3 0f 1e fb          	endbr32 
801001e5:	55                   	push   %ebp
801001e6:	89 e5                	mov    %esp,%ebp
801001e8:	56                   	push   %esi
801001e9:	53                   	push   %ebx
801001ea:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holdingsleep(&b->lock))
801001ed:	8d 73 0c             	lea    0xc(%ebx),%esi
801001f0:	83 ec 0c             	sub    $0xc,%esp
801001f3:	56                   	push   %esi
801001f4:	e8 f9 39 00 00       	call   80103bf2 <holdingsleep>
801001f9:	83 c4 10             	add    $0x10,%esp
801001fc:	85 c0                	test   %eax,%eax
801001fe:	74 6b                	je     8010026b <brelse+0x8a>
    panic("brelse");

  releasesleep(&b->lock);
80100200:	83 ec 0c             	sub    $0xc,%esp
80100203:	56                   	push   %esi
80100204:	e8 aa 39 00 00       	call   80103bb3 <releasesleep>

  acquire(&bcache.lock);
80100209:	c7 04 24 20 d6 10 80 	movl   $0x8010d620,(%esp)
80100210:	e8 58 3b 00 00       	call   80103d6d <acquire>
  b->refcnt--;
80100215:	8b 43 4c             	mov    0x4c(%ebx),%eax
80100218:	83 e8 01             	sub    $0x1,%eax
8010021b:	89 43 4c             	mov    %eax,0x4c(%ebx)
  if (b->refcnt == 0) {
8010021e:	83 c4 10             	add    $0x10,%esp
80100221:	85 c0                	test   %eax,%eax
80100223:	75 2f                	jne    80100254 <brelse+0x73>
    // no one is waiting for it.
    b->next->prev = b->prev;
80100225:	8b 43 54             	mov    0x54(%ebx),%eax
80100228:	8b 53 50             	mov    0x50(%ebx),%edx
8010022b:	89 50 50             	mov    %edx,0x50(%eax)
    b->prev->next = b->next;
8010022e:	8b 43 50             	mov    0x50(%ebx),%eax
80100231:	8b 53 54             	mov    0x54(%ebx),%edx
80100234:	89 50 54             	mov    %edx,0x54(%eax)
    b->next = bcache.head.next;
80100237:	a1 70 1d 11 80       	mov    0x80111d70,%eax
8010023c:	89 43 54             	mov    %eax,0x54(%ebx)
    b->prev = &bcache.head;
8010023f:	c7 43 50 1c 1d 11 80 	movl   $0x80111d1c,0x50(%ebx)
    bcache.head.next->prev = b;
80100246:	a1 70 1d 11 80       	mov    0x80111d70,%eax
8010024b:	89 58 50             	mov    %ebx,0x50(%eax)
    bcache.head.next = b;
8010024e:	89 1d 70 1d 11 80    	mov    %ebx,0x80111d70
  }
  
  release(&bcache.lock);
80100254:	83 ec 0c             	sub    $0xc,%esp
80100257:	68 20 d6 10 80       	push   $0x8010d620
8010025c:	e8 75 3b 00 00       	call   80103dd6 <release>
}
80100261:	83 c4 10             	add    $0x10,%esp
80100264:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100267:	5b                   	pop    %ebx
80100268:	5e                   	pop    %esi
80100269:	5d                   	pop    %ebp
8010026a:	c3                   	ret    
    panic("brelse");
8010026b:	83 ec 0c             	sub    $0xc,%esp
8010026e:	68 86 66 10 80       	push   $0x80106686
80100273:	e8 e4 00 00 00       	call   8010035c <panic>

80100278 <consoleread>:
#endif
}

int
consoleread(struct inode *ip, char *dst, int n)
{
80100278:	f3 0f 1e fb          	endbr32 
8010027c:	55                   	push   %ebp
8010027d:	89 e5                	mov    %esp,%ebp
8010027f:	57                   	push   %edi
80100280:	56                   	push   %esi
80100281:	53                   	push   %ebx
80100282:	83 ec 28             	sub    $0x28,%esp
80100285:	8b 7d 08             	mov    0x8(%ebp),%edi
80100288:	8b 75 0c             	mov    0xc(%ebp),%esi
8010028b:	8b 5d 10             	mov    0x10(%ebp),%ebx
  uint target;
  int c;

  iunlock(ip);
8010028e:	57                   	push   %edi
8010028f:	e8 39 14 00 00       	call   801016cd <iunlock>
  target = n;
80100294:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  acquire(&cons.lock);
80100297:	c7 04 24 20 a5 10 80 	movl   $0x8010a520,(%esp)
8010029e:	e8 ca 3a 00 00       	call   80103d6d <acquire>
  while(n > 0){
801002a3:	83 c4 10             	add    $0x10,%esp
801002a6:	85 db                	test   %ebx,%ebx
801002a8:	0f 8e 8f 00 00 00    	jle    8010033d <consoleread+0xc5>
    while(input.r == input.w){
801002ae:	a1 00 20 11 80       	mov    0x80112000,%eax
801002b3:	3b 05 04 20 11 80    	cmp    0x80112004,%eax
801002b9:	75 47                	jne    80100302 <consoleread+0x8a>
      if(myproc()->killed){
801002bb:	e8 5a 30 00 00       	call   8010331a <myproc>
801002c0:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801002c4:	75 17                	jne    801002dd <consoleread+0x65>
        release(&cons.lock);
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &cons.lock);
801002c6:	83 ec 08             	sub    $0x8,%esp
801002c9:	68 20 a5 10 80       	push   $0x8010a520
801002ce:	68 00 20 11 80       	push   $0x80112000
801002d3:	e8 28 35 00 00       	call   80103800 <sleep>
801002d8:	83 c4 10             	add    $0x10,%esp
801002db:	eb d1                	jmp    801002ae <consoleread+0x36>
        release(&cons.lock);
801002dd:	83 ec 0c             	sub    $0xc,%esp
801002e0:	68 20 a5 10 80       	push   $0x8010a520
801002e5:	e8 ec 3a 00 00       	call   80103dd6 <release>
        ilock(ip);
801002ea:	89 3c 24             	mov    %edi,(%esp)
801002ed:	e8 15 13 00 00       	call   80101607 <ilock>
        return -1;
801002f2:	83 c4 10             	add    $0x10,%esp
801002f5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  release(&cons.lock);
  ilock(ip);

  return target - n;
}
801002fa:	8d 65 f4             	lea    -0xc(%ebp),%esp
801002fd:	5b                   	pop    %ebx
801002fe:	5e                   	pop    %esi
801002ff:	5f                   	pop    %edi
80100300:	5d                   	pop    %ebp
80100301:	c3                   	ret    
    c = input.buf[input.r++ % INPUT_BUF];
80100302:	8d 50 01             	lea    0x1(%eax),%edx
80100305:	89 15 00 20 11 80    	mov    %edx,0x80112000
8010030b:	89 c2                	mov    %eax,%edx
8010030d:	83 e2 7f             	and    $0x7f,%edx
80100310:	0f b6 92 80 1f 11 80 	movzbl -0x7feee080(%edx),%edx
80100317:	0f be ca             	movsbl %dl,%ecx
    if(c == C('D')){  // EOF
8010031a:	80 fa 04             	cmp    $0x4,%dl
8010031d:	74 14                	je     80100333 <consoleread+0xbb>
    *dst++ = c;
8010031f:	8d 46 01             	lea    0x1(%esi),%eax
80100322:	88 16                	mov    %dl,(%esi)
    --n;
80100324:	83 eb 01             	sub    $0x1,%ebx
    if(c == '\n')
80100327:	83 f9 0a             	cmp    $0xa,%ecx
8010032a:	74 11                	je     8010033d <consoleread+0xc5>
    *dst++ = c;
8010032c:	89 c6                	mov    %eax,%esi
8010032e:	e9 73 ff ff ff       	jmp    801002a6 <consoleread+0x2e>
      if(n < target){
80100333:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
80100336:	73 05                	jae    8010033d <consoleread+0xc5>
        input.r--;
80100338:	a3 00 20 11 80       	mov    %eax,0x80112000
  release(&cons.lock);
8010033d:	83 ec 0c             	sub    $0xc,%esp
80100340:	68 20 a5 10 80       	push   $0x8010a520
80100345:	e8 8c 3a 00 00       	call   80103dd6 <release>
  ilock(ip);
8010034a:	89 3c 24             	mov    %edi,(%esp)
8010034d:	e8 b5 12 00 00       	call   80101607 <ilock>
  return target - n;
80100352:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100355:	29 d8                	sub    %ebx,%eax
80100357:	83 c4 10             	add    $0x10,%esp
8010035a:	eb 9e                	jmp    801002fa <consoleread+0x82>

8010035c <panic>:
{
8010035c:	f3 0f 1e fb          	endbr32 
80100360:	55                   	push   %ebp
80100361:	89 e5                	mov    %esp,%ebp
80100363:	53                   	push   %ebx
80100364:	83 ec 34             	sub    $0x34,%esp
}

static inline void
cli(void)
{
  asm volatile("cli");
80100367:	fa                   	cli    
  cons.locking = 0;
80100368:	c7 05 54 a5 10 80 00 	movl   $0x0,0x8010a554
8010036f:	00 00 00 
  cprintf("lapicid %d: panic: ", lapicid());
80100372:	e8 df 20 00 00       	call   80102456 <lapicid>
80100377:	83 ec 08             	sub    $0x8,%esp
8010037a:	50                   	push   %eax
8010037b:	68 8d 66 10 80       	push   $0x8010668d
80100380:	e8 a4 02 00 00       	call   80100629 <cprintf>
  cprintf(s);
80100385:	83 c4 04             	add    $0x4,%esp
80100388:	ff 75 08             	pushl  0x8(%ebp)
8010038b:	e8 99 02 00 00       	call   80100629 <cprintf>
  cprintf("\n");
80100390:	c7 04 24 fb 6f 10 80 	movl   $0x80106ffb,(%esp)
80100397:	e8 8d 02 00 00       	call   80100629 <cprintf>
  getcallerpcs(&s, pcs);
8010039c:	83 c4 08             	add    $0x8,%esp
8010039f:	8d 45 d0             	lea    -0x30(%ebp),%eax
801003a2:	50                   	push   %eax
801003a3:	8d 45 08             	lea    0x8(%ebp),%eax
801003a6:	50                   	push   %eax
801003a7:	e8 90 38 00 00       	call   80103c3c <getcallerpcs>
  for(i=0; i<10; i++)
801003ac:	83 c4 10             	add    $0x10,%esp
801003af:	bb 00 00 00 00       	mov    $0x0,%ebx
801003b4:	eb 17                	jmp    801003cd <panic+0x71>
    cprintf(" %p", pcs[i]);
801003b6:	83 ec 08             	sub    $0x8,%esp
801003b9:	ff 74 9d d0          	pushl  -0x30(%ebp,%ebx,4)
801003bd:	68 a1 66 10 80       	push   $0x801066a1
801003c2:	e8 62 02 00 00       	call   80100629 <cprintf>
  for(i=0; i<10; i++)
801003c7:	83 c3 01             	add    $0x1,%ebx
801003ca:	83 c4 10             	add    $0x10,%esp
801003cd:	83 fb 09             	cmp    $0x9,%ebx
801003d0:	7e e4                	jle    801003b6 <panic+0x5a>
  panicked = 1; // freeze other CPU
801003d2:	c7 05 58 a5 10 80 01 	movl   $0x1,0x8010a558
801003d9:	00 00 00 
  for(;;)
801003dc:	eb fe                	jmp    801003dc <panic+0x80>

801003de <cgaputc>:
{
801003de:	55                   	push   %ebp
801003df:	89 e5                	mov    %esp,%ebp
801003e1:	57                   	push   %edi
801003e2:	56                   	push   %esi
801003e3:	53                   	push   %ebx
801003e4:	83 ec 0c             	sub    $0xc,%esp
801003e7:	89 c6                	mov    %eax,%esi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801003e9:	b9 d4 03 00 00       	mov    $0x3d4,%ecx
801003ee:	b8 0e 00 00 00       	mov    $0xe,%eax
801003f3:	89 ca                	mov    %ecx,%edx
801003f5:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801003f6:	bb d5 03 00 00       	mov    $0x3d5,%ebx
801003fb:	89 da                	mov    %ebx,%edx
801003fd:	ec                   	in     (%dx),%al
  pos = inb(CRTPORT+1) << 8;
801003fe:	0f b6 f8             	movzbl %al,%edi
80100401:	c1 e7 08             	shl    $0x8,%edi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80100404:	b8 0f 00 00 00       	mov    $0xf,%eax
80100409:	89 ca                	mov    %ecx,%edx
8010040b:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010040c:	89 da                	mov    %ebx,%edx
8010040e:	ec                   	in     (%dx),%al
  pos |= inb(CRTPORT+1);
8010040f:	0f b6 c8             	movzbl %al,%ecx
80100412:	09 f9                	or     %edi,%ecx
  if(c == '\n')
80100414:	83 fe 0a             	cmp    $0xa,%esi
80100417:	74 66                	je     8010047f <cgaputc+0xa1>
  else if(c == BACKSPACE){
80100419:	81 fe 00 01 00 00    	cmp    $0x100,%esi
8010041f:	74 7f                	je     801004a0 <cgaputc+0xc2>
    crt[pos++] = (c&0xff) | 0x0700;  // black on white
80100421:	89 f0                	mov    %esi,%eax
80100423:	0f b6 f0             	movzbl %al,%esi
80100426:	8d 59 01             	lea    0x1(%ecx),%ebx
80100429:	66 81 ce 00 07       	or     $0x700,%si
8010042e:	66 89 b4 09 00 80 0b 	mov    %si,-0x7ff48000(%ecx,%ecx,1)
80100435:	80 
  if(pos < 0 || pos > 25*80)
80100436:	81 fb d0 07 00 00    	cmp    $0x7d0,%ebx
8010043c:	77 6f                	ja     801004ad <cgaputc+0xcf>
  if((pos/80) >= 24){  // Scroll up.
8010043e:	81 fb 7f 07 00 00    	cmp    $0x77f,%ebx
80100444:	7f 74                	jg     801004ba <cgaputc+0xdc>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80100446:	be d4 03 00 00       	mov    $0x3d4,%esi
8010044b:	b8 0e 00 00 00       	mov    $0xe,%eax
80100450:	89 f2                	mov    %esi,%edx
80100452:	ee                   	out    %al,(%dx)
  outb(CRTPORT+1, pos>>8);
80100453:	89 d8                	mov    %ebx,%eax
80100455:	c1 f8 08             	sar    $0x8,%eax
80100458:	b9 d5 03 00 00       	mov    $0x3d5,%ecx
8010045d:	89 ca                	mov    %ecx,%edx
8010045f:	ee                   	out    %al,(%dx)
80100460:	b8 0f 00 00 00       	mov    $0xf,%eax
80100465:	89 f2                	mov    %esi,%edx
80100467:	ee                   	out    %al,(%dx)
80100468:	89 d8                	mov    %ebx,%eax
8010046a:	89 ca                	mov    %ecx,%edx
8010046c:	ee                   	out    %al,(%dx)
  crt[pos] = ' ' | 0x0700;
8010046d:	66 c7 84 1b 00 80 0b 	movw   $0x720,-0x7ff48000(%ebx,%ebx,1)
80100474:	80 20 07 
}
80100477:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010047a:	5b                   	pop    %ebx
8010047b:	5e                   	pop    %esi
8010047c:	5f                   	pop    %edi
8010047d:	5d                   	pop    %ebp
8010047e:	c3                   	ret    
    pos += 80 - pos%80;
8010047f:	ba 67 66 66 66       	mov    $0x66666667,%edx
80100484:	89 c8                	mov    %ecx,%eax
80100486:	f7 ea                	imul   %edx
80100488:	c1 fa 05             	sar    $0x5,%edx
8010048b:	8d 04 92             	lea    (%edx,%edx,4),%eax
8010048e:	c1 e0 04             	shl    $0x4,%eax
80100491:	89 ca                	mov    %ecx,%edx
80100493:	29 c2                	sub    %eax,%edx
80100495:	bb 50 00 00 00       	mov    $0x50,%ebx
8010049a:	29 d3                	sub    %edx,%ebx
8010049c:	01 cb                	add    %ecx,%ebx
8010049e:	eb 96                	jmp    80100436 <cgaputc+0x58>
    if(pos > 0) --pos;
801004a0:	85 c9                	test   %ecx,%ecx
801004a2:	7e 05                	jle    801004a9 <cgaputc+0xcb>
801004a4:	8d 59 ff             	lea    -0x1(%ecx),%ebx
801004a7:	eb 8d                	jmp    80100436 <cgaputc+0x58>
  pos |= inb(CRTPORT+1);
801004a9:	89 cb                	mov    %ecx,%ebx
801004ab:	eb 89                	jmp    80100436 <cgaputc+0x58>
    panic("pos under/overflow");
801004ad:	83 ec 0c             	sub    $0xc,%esp
801004b0:	68 a5 66 10 80       	push   $0x801066a5
801004b5:	e8 a2 fe ff ff       	call   8010035c <panic>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
801004ba:	83 ec 04             	sub    $0x4,%esp
801004bd:	68 60 0e 00 00       	push   $0xe60
801004c2:	68 a0 80 0b 80       	push   $0x800b80a0
801004c7:	68 00 80 0b 80       	push   $0x800b8000
801004cc:	e8 d0 39 00 00       	call   80103ea1 <memmove>
    pos -= 80;
801004d1:	83 eb 50             	sub    $0x50,%ebx
    memset(crt+pos, 0, sizeof(crt[0])*(24*80 - pos));
801004d4:	b8 80 07 00 00       	mov    $0x780,%eax
801004d9:	29 d8                	sub    %ebx,%eax
801004db:	8d 94 1b 00 80 0b 80 	lea    -0x7ff48000(%ebx,%ebx,1),%edx
801004e2:	83 c4 0c             	add    $0xc,%esp
801004e5:	01 c0                	add    %eax,%eax
801004e7:	50                   	push   %eax
801004e8:	6a 00                	push   $0x0
801004ea:	52                   	push   %edx
801004eb:	e8 31 39 00 00       	call   80103e21 <memset>
801004f0:	83 c4 10             	add    $0x10,%esp
801004f3:	e9 4e ff ff ff       	jmp    80100446 <cgaputc+0x68>

801004f8 <consputc>:
  if(panicked){
801004f8:	83 3d 58 a5 10 80 00 	cmpl   $0x0,0x8010a558
801004ff:	74 03                	je     80100504 <consputc+0xc>
  asm volatile("cli");
80100501:	fa                   	cli    
    for(;;)
80100502:	eb fe                	jmp    80100502 <consputc+0xa>
{
80100504:	55                   	push   %ebp
80100505:	89 e5                	mov    %esp,%ebp
80100507:	53                   	push   %ebx
80100508:	83 ec 04             	sub    $0x4,%esp
8010050b:	89 c3                	mov    %eax,%ebx
  if(c == BACKSPACE){
8010050d:	3d 00 01 00 00       	cmp    $0x100,%eax
80100512:	74 18                	je     8010052c <consputc+0x34>
    uartputc(c);
80100514:	83 ec 0c             	sub    $0xc,%esp
80100517:	50                   	push   %eax
80100518:	e8 01 4d 00 00       	call   8010521e <uartputc>
8010051d:	83 c4 10             	add    $0x10,%esp
  cgaputc(c);
80100520:	89 d8                	mov    %ebx,%eax
80100522:	e8 b7 fe ff ff       	call   801003de <cgaputc>
}
80100527:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010052a:	c9                   	leave  
8010052b:	c3                   	ret    
    uartputc('\b'); uartputc(' '); uartputc('\b');
8010052c:	83 ec 0c             	sub    $0xc,%esp
8010052f:	6a 08                	push   $0x8
80100531:	e8 e8 4c 00 00       	call   8010521e <uartputc>
80100536:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010053d:	e8 dc 4c 00 00       	call   8010521e <uartputc>
80100542:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100549:	e8 d0 4c 00 00       	call   8010521e <uartputc>
8010054e:	83 c4 10             	add    $0x10,%esp
80100551:	eb cd                	jmp    80100520 <consputc+0x28>

80100553 <printint>:
{
80100553:	55                   	push   %ebp
80100554:	89 e5                	mov    %esp,%ebp
80100556:	57                   	push   %edi
80100557:	56                   	push   %esi
80100558:	53                   	push   %ebx
80100559:	83 ec 2c             	sub    $0x2c,%esp
8010055c:	89 d6                	mov    %edx,%esi
8010055e:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  if(sign && (sign = xx < 0))
80100561:	85 c9                	test   %ecx,%ecx
80100563:	74 0c                	je     80100571 <printint+0x1e>
80100565:	89 c7                	mov    %eax,%edi
80100567:	c1 ef 1f             	shr    $0x1f,%edi
8010056a:	89 7d d4             	mov    %edi,-0x2c(%ebp)
8010056d:	85 c0                	test   %eax,%eax
8010056f:	78 38                	js     801005a9 <printint+0x56>
    x = xx;
80100571:	89 c1                	mov    %eax,%ecx
  i = 0;
80100573:	bb 00 00 00 00       	mov    $0x0,%ebx
    buf[i++] = digits[x % base];
80100578:	89 c8                	mov    %ecx,%eax
8010057a:	ba 00 00 00 00       	mov    $0x0,%edx
8010057f:	f7 f6                	div    %esi
80100581:	89 df                	mov    %ebx,%edi
80100583:	83 c3 01             	add    $0x1,%ebx
80100586:	0f b6 92 e4 66 10 80 	movzbl -0x7fef991c(%edx),%edx
8010058d:	88 54 3d d8          	mov    %dl,-0x28(%ebp,%edi,1)
  }while((x /= base) != 0);
80100591:	89 ca                	mov    %ecx,%edx
80100593:	89 c1                	mov    %eax,%ecx
80100595:	39 d6                	cmp    %edx,%esi
80100597:	76 df                	jbe    80100578 <printint+0x25>
  if(sign)
80100599:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
8010059d:	74 1a                	je     801005b9 <printint+0x66>
    buf[i++] = '-';
8010059f:	c6 44 1d d8 2d       	movb   $0x2d,-0x28(%ebp,%ebx,1)
801005a4:	8d 5f 02             	lea    0x2(%edi),%ebx
801005a7:	eb 10                	jmp    801005b9 <printint+0x66>
    x = -xx;
801005a9:	f7 d8                	neg    %eax
801005ab:	89 c1                	mov    %eax,%ecx
801005ad:	eb c4                	jmp    80100573 <printint+0x20>
    consputc(buf[i]);
801005af:	0f be 44 1d d8       	movsbl -0x28(%ebp,%ebx,1),%eax
801005b4:	e8 3f ff ff ff       	call   801004f8 <consputc>
  while(--i >= 0)
801005b9:	83 eb 01             	sub    $0x1,%ebx
801005bc:	79 f1                	jns    801005af <printint+0x5c>
}
801005be:	83 c4 2c             	add    $0x2c,%esp
801005c1:	5b                   	pop    %ebx
801005c2:	5e                   	pop    %esi
801005c3:	5f                   	pop    %edi
801005c4:	5d                   	pop    %ebp
801005c5:	c3                   	ret    

801005c6 <consolewrite>:

int
consolewrite(struct inode *ip, char *buf, int n)
{
801005c6:	f3 0f 1e fb          	endbr32 
801005ca:	55                   	push   %ebp
801005cb:	89 e5                	mov    %esp,%ebp
801005cd:	57                   	push   %edi
801005ce:	56                   	push   %esi
801005cf:	53                   	push   %ebx
801005d0:	83 ec 18             	sub    $0x18,%esp
801005d3:	8b 7d 0c             	mov    0xc(%ebp),%edi
801005d6:	8b 75 10             	mov    0x10(%ebp),%esi
  int i;

  iunlock(ip);
801005d9:	ff 75 08             	pushl  0x8(%ebp)
801005dc:	e8 ec 10 00 00       	call   801016cd <iunlock>
  acquire(&cons.lock);
801005e1:	c7 04 24 20 a5 10 80 	movl   $0x8010a520,(%esp)
801005e8:	e8 80 37 00 00       	call   80103d6d <acquire>
  for(i = 0; i < n; i++)
801005ed:	83 c4 10             	add    $0x10,%esp
801005f0:	bb 00 00 00 00       	mov    $0x0,%ebx
801005f5:	39 f3                	cmp    %esi,%ebx
801005f7:	7d 0e                	jge    80100607 <consolewrite+0x41>
    consputc(buf[i] & 0xff);
801005f9:	0f b6 04 1f          	movzbl (%edi,%ebx,1),%eax
801005fd:	e8 f6 fe ff ff       	call   801004f8 <consputc>
  for(i = 0; i < n; i++)
80100602:	83 c3 01             	add    $0x1,%ebx
80100605:	eb ee                	jmp    801005f5 <consolewrite+0x2f>
  release(&cons.lock);
80100607:	83 ec 0c             	sub    $0xc,%esp
8010060a:	68 20 a5 10 80       	push   $0x8010a520
8010060f:	e8 c2 37 00 00       	call   80103dd6 <release>
  ilock(ip);
80100614:	83 c4 04             	add    $0x4,%esp
80100617:	ff 75 08             	pushl  0x8(%ebp)
8010061a:	e8 e8 0f 00 00       	call   80101607 <ilock>

  return n;
}
8010061f:	89 f0                	mov    %esi,%eax
80100621:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100624:	5b                   	pop    %ebx
80100625:	5e                   	pop    %esi
80100626:	5f                   	pop    %edi
80100627:	5d                   	pop    %ebp
80100628:	c3                   	ret    

80100629 <cprintf>:
{
80100629:	f3 0f 1e fb          	endbr32 
8010062d:	55                   	push   %ebp
8010062e:	89 e5                	mov    %esp,%ebp
80100630:	57                   	push   %edi
80100631:	56                   	push   %esi
80100632:	53                   	push   %ebx
80100633:	83 ec 1c             	sub    $0x1c,%esp
  locking = cons.locking;
80100636:	a1 54 a5 10 80       	mov    0x8010a554,%eax
8010063b:	89 45 e0             	mov    %eax,-0x20(%ebp)
  if(locking)
8010063e:	85 c0                	test   %eax,%eax
80100640:	75 10                	jne    80100652 <cprintf+0x29>
  if (fmt == 0)
80100642:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80100646:	74 1c                	je     80100664 <cprintf+0x3b>
  argp = (uint*)(void*)(&fmt + 1);
80100648:	8d 7d 0c             	lea    0xc(%ebp),%edi
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
8010064b:	be 00 00 00 00       	mov    $0x0,%esi
80100650:	eb 27                	jmp    80100679 <cprintf+0x50>
    acquire(&cons.lock);
80100652:	83 ec 0c             	sub    $0xc,%esp
80100655:	68 20 a5 10 80       	push   $0x8010a520
8010065a:	e8 0e 37 00 00       	call   80103d6d <acquire>
8010065f:	83 c4 10             	add    $0x10,%esp
80100662:	eb de                	jmp    80100642 <cprintf+0x19>
    panic("null fmt");
80100664:	83 ec 0c             	sub    $0xc,%esp
80100667:	68 bf 66 10 80       	push   $0x801066bf
8010066c:	e8 eb fc ff ff       	call   8010035c <panic>
      consputc(c);
80100671:	e8 82 fe ff ff       	call   801004f8 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
80100676:	83 c6 01             	add    $0x1,%esi
80100679:	8b 55 08             	mov    0x8(%ebp),%edx
8010067c:	0f b6 04 32          	movzbl (%edx,%esi,1),%eax
80100680:	85 c0                	test   %eax,%eax
80100682:	0f 84 b1 00 00 00    	je     80100739 <cprintf+0x110>
    if(c != '%'){
80100688:	83 f8 25             	cmp    $0x25,%eax
8010068b:	75 e4                	jne    80100671 <cprintf+0x48>
    c = fmt[++i] & 0xff;
8010068d:	83 c6 01             	add    $0x1,%esi
80100690:	0f b6 1c 32          	movzbl (%edx,%esi,1),%ebx
    if(c == 0)
80100694:	85 db                	test   %ebx,%ebx
80100696:	0f 84 9d 00 00 00    	je     80100739 <cprintf+0x110>
    switch(c){
8010069c:	83 fb 70             	cmp    $0x70,%ebx
8010069f:	74 2e                	je     801006cf <cprintf+0xa6>
801006a1:	7f 22                	jg     801006c5 <cprintf+0x9c>
801006a3:	83 fb 25             	cmp    $0x25,%ebx
801006a6:	74 6c                	je     80100714 <cprintf+0xeb>
801006a8:	83 fb 64             	cmp    $0x64,%ebx
801006ab:	75 76                	jne    80100723 <cprintf+0xfa>
      printint(*argp++, 10, 1);
801006ad:	8d 5f 04             	lea    0x4(%edi),%ebx
801006b0:	8b 07                	mov    (%edi),%eax
801006b2:	b9 01 00 00 00       	mov    $0x1,%ecx
801006b7:	ba 0a 00 00 00       	mov    $0xa,%edx
801006bc:	e8 92 fe ff ff       	call   80100553 <printint>
801006c1:	89 df                	mov    %ebx,%edi
      break;
801006c3:	eb b1                	jmp    80100676 <cprintf+0x4d>
    switch(c){
801006c5:	83 fb 73             	cmp    $0x73,%ebx
801006c8:	74 1d                	je     801006e7 <cprintf+0xbe>
801006ca:	83 fb 78             	cmp    $0x78,%ebx
801006cd:	75 54                	jne    80100723 <cprintf+0xfa>
      printint(*argp++, 16, 0);
801006cf:	8d 5f 04             	lea    0x4(%edi),%ebx
801006d2:	8b 07                	mov    (%edi),%eax
801006d4:	b9 00 00 00 00       	mov    $0x0,%ecx
801006d9:	ba 10 00 00 00       	mov    $0x10,%edx
801006de:	e8 70 fe ff ff       	call   80100553 <printint>
801006e3:	89 df                	mov    %ebx,%edi
      break;
801006e5:	eb 8f                	jmp    80100676 <cprintf+0x4d>
      if((s = (char*)*argp++) == 0)
801006e7:	8d 47 04             	lea    0x4(%edi),%eax
801006ea:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801006ed:	8b 1f                	mov    (%edi),%ebx
801006ef:	85 db                	test   %ebx,%ebx
801006f1:	75 05                	jne    801006f8 <cprintf+0xcf>
        s = "(null)";
801006f3:	bb b8 66 10 80       	mov    $0x801066b8,%ebx
      for(; *s; s++)
801006f8:	0f b6 03             	movzbl (%ebx),%eax
801006fb:	84 c0                	test   %al,%al
801006fd:	74 0d                	je     8010070c <cprintf+0xe3>
        consputc(*s);
801006ff:	0f be c0             	movsbl %al,%eax
80100702:	e8 f1 fd ff ff       	call   801004f8 <consputc>
      for(; *s; s++)
80100707:	83 c3 01             	add    $0x1,%ebx
8010070a:	eb ec                	jmp    801006f8 <cprintf+0xcf>
      if((s = (char*)*argp++) == 0)
8010070c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
8010070f:	e9 62 ff ff ff       	jmp    80100676 <cprintf+0x4d>
      consputc('%');
80100714:	b8 25 00 00 00       	mov    $0x25,%eax
80100719:	e8 da fd ff ff       	call   801004f8 <consputc>
      break;
8010071e:	e9 53 ff ff ff       	jmp    80100676 <cprintf+0x4d>
      consputc('%');
80100723:	b8 25 00 00 00       	mov    $0x25,%eax
80100728:	e8 cb fd ff ff       	call   801004f8 <consputc>
      consputc(c);
8010072d:	89 d8                	mov    %ebx,%eax
8010072f:	e8 c4 fd ff ff       	call   801004f8 <consputc>
      break;
80100734:	e9 3d ff ff ff       	jmp    80100676 <cprintf+0x4d>
  if(locking)
80100739:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
8010073d:	75 08                	jne    80100747 <cprintf+0x11e>
}
8010073f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100742:	5b                   	pop    %ebx
80100743:	5e                   	pop    %esi
80100744:	5f                   	pop    %edi
80100745:	5d                   	pop    %ebp
80100746:	c3                   	ret    
    release(&cons.lock);
80100747:	83 ec 0c             	sub    $0xc,%esp
8010074a:	68 20 a5 10 80       	push   $0x8010a520
8010074f:	e8 82 36 00 00       	call   80103dd6 <release>
80100754:	83 c4 10             	add    $0x10,%esp
}
80100757:	eb e6                	jmp    8010073f <cprintf+0x116>

80100759 <do_shutdown>:
{
80100759:	f3 0f 1e fb          	endbr32 
8010075d:	55                   	push   %ebp
8010075e:	89 e5                	mov    %esp,%ebp
80100760:	83 ec 14             	sub    $0x14,%esp
  cprintf("\nShutting down ...\n");
80100763:	68 c8 66 10 80       	push   $0x801066c8
80100768:	e8 bc fe ff ff       	call   80100629 <cprintf>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010076d:	b8 00 20 00 00       	mov    $0x2000,%eax
80100772:	ba 04 06 00 00       	mov    $0x604,%edx
80100777:	66 ef                	out    %ax,(%dx)
  return;  // not reached
80100779:	83 c4 10             	add    $0x10,%esp
}
8010077c:	c9                   	leave  
8010077d:	c3                   	ret    

8010077e <consoleintr>:
{
8010077e:	f3 0f 1e fb          	endbr32 
80100782:	55                   	push   %ebp
80100783:	89 e5                	mov    %esp,%ebp
80100785:	57                   	push   %edi
80100786:	56                   	push   %esi
80100787:	53                   	push   %ebx
80100788:	83 ec 28             	sub    $0x28,%esp
8010078b:	8b 75 08             	mov    0x8(%ebp),%esi
  acquire(&cons.lock);
8010078e:	68 20 a5 10 80       	push   $0x8010a520
80100793:	e8 d5 35 00 00       	call   80103d6d <acquire>
  while((c = getc()) >= 0){
80100798:	83 c4 10             	add    $0x10,%esp
  int shutdown = FALSE;
8010079b:	bf 00 00 00 00       	mov    $0x0,%edi
  int c, doprocdump = 0;
801007a0:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
  while((c = getc()) >= 0){
801007a7:	e9 d5 00 00 00       	jmp    80100881 <consoleintr+0x103>
    switch(c){
801007ac:	83 fb 15             	cmp    $0x15,%ebx
801007af:	0f 84 94 00 00 00    	je     80100849 <consoleintr+0xcb>
801007b5:	83 fb 7f             	cmp    $0x7f,%ebx
801007b8:	0f 84 e4 00 00 00    	je     801008a2 <consoleintr+0x124>
      if(c != 0 && input.e-input.r < INPUT_BUF){
801007be:	85 db                	test   %ebx,%ebx
801007c0:	0f 84 bb 00 00 00    	je     80100881 <consoleintr+0x103>
801007c6:	a1 08 20 11 80       	mov    0x80112008,%eax
801007cb:	89 c2                	mov    %eax,%edx
801007cd:	2b 15 00 20 11 80    	sub    0x80112000,%edx
801007d3:	83 fa 7f             	cmp    $0x7f,%edx
801007d6:	0f 87 a5 00 00 00    	ja     80100881 <consoleintr+0x103>
        c = (c == '\r') ? '\n' : c;
801007dc:	83 fb 0d             	cmp    $0xd,%ebx
801007df:	0f 84 84 00 00 00    	je     80100869 <consoleintr+0xeb>
        input.buf[input.e++ % INPUT_BUF] = c;
801007e5:	8d 50 01             	lea    0x1(%eax),%edx
801007e8:	89 15 08 20 11 80    	mov    %edx,0x80112008
801007ee:	83 e0 7f             	and    $0x7f,%eax
801007f1:	88 98 80 1f 11 80    	mov    %bl,-0x7feee080(%eax)
        consputc(c);
801007f7:	89 d8                	mov    %ebx,%eax
801007f9:	e8 fa fc ff ff       	call   801004f8 <consputc>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
801007fe:	83 fb 0a             	cmp    $0xa,%ebx
80100801:	0f 94 c2             	sete   %dl
80100804:	83 fb 04             	cmp    $0x4,%ebx
80100807:	0f 94 c0             	sete   %al
8010080a:	08 c2                	or     %al,%dl
8010080c:	75 10                	jne    8010081e <consoleintr+0xa0>
8010080e:	a1 00 20 11 80       	mov    0x80112000,%eax
80100813:	83 e8 80             	sub    $0xffffff80,%eax
80100816:	39 05 08 20 11 80    	cmp    %eax,0x80112008
8010081c:	75 63                	jne    80100881 <consoleintr+0x103>
          input.w = input.e;
8010081e:	a1 08 20 11 80       	mov    0x80112008,%eax
80100823:	a3 04 20 11 80       	mov    %eax,0x80112004
          wakeup(&input.r);
80100828:	83 ec 0c             	sub    $0xc,%esp
8010082b:	68 00 20 11 80       	push   $0x80112000
80100830:	e8 37 31 00 00       	call   8010396c <wakeup>
80100835:	83 c4 10             	add    $0x10,%esp
80100838:	eb 47                	jmp    80100881 <consoleintr+0x103>
        input.e--;
8010083a:	a3 08 20 11 80       	mov    %eax,0x80112008
        consputc(BACKSPACE);
8010083f:	b8 00 01 00 00       	mov    $0x100,%eax
80100844:	e8 af fc ff ff       	call   801004f8 <consputc>
      while(input.e != input.w &&
80100849:	a1 08 20 11 80       	mov    0x80112008,%eax
8010084e:	3b 05 04 20 11 80    	cmp    0x80112004,%eax
80100854:	74 2b                	je     80100881 <consoleintr+0x103>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
80100856:	83 e8 01             	sub    $0x1,%eax
80100859:	89 c2                	mov    %eax,%edx
8010085b:	83 e2 7f             	and    $0x7f,%edx
      while(input.e != input.w &&
8010085e:	80 ba 80 1f 11 80 0a 	cmpb   $0xa,-0x7feee080(%edx)
80100865:	75 d3                	jne    8010083a <consoleintr+0xbc>
80100867:	eb 18                	jmp    80100881 <consoleintr+0x103>
        c = (c == '\r') ? '\n' : c;
80100869:	bb 0a 00 00 00       	mov    $0xa,%ebx
8010086e:	e9 72 ff ff ff       	jmp    801007e5 <consoleintr+0x67>
    switch(c){
80100873:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
8010087a:	eb 05                	jmp    80100881 <consoleintr+0x103>
      shutdown = TRUE;
8010087c:	bf 01 00 00 00       	mov    $0x1,%edi
  while((c = getc()) >= 0){
80100881:	ff d6                	call   *%esi
80100883:	89 c3                	mov    %eax,%ebx
80100885:	85 c0                	test   %eax,%eax
80100887:	78 3a                	js     801008c3 <consoleintr+0x145>
    switch(c){
80100889:	83 fb 10             	cmp    $0x10,%ebx
8010088c:	74 e5                	je     80100873 <consoleintr+0xf5>
8010088e:	0f 8f 18 ff ff ff    	jg     801007ac <consoleintr+0x2e>
80100894:	83 fb 04             	cmp    $0x4,%ebx
80100897:	74 e3                	je     8010087c <consoleintr+0xfe>
80100899:	83 fb 08             	cmp    $0x8,%ebx
8010089c:	0f 85 1c ff ff ff    	jne    801007be <consoleintr+0x40>
      if(input.e != input.w){
801008a2:	a1 08 20 11 80       	mov    0x80112008,%eax
801008a7:	3b 05 04 20 11 80    	cmp    0x80112004,%eax
801008ad:	74 d2                	je     80100881 <consoleintr+0x103>
        input.e--;
801008af:	83 e8 01             	sub    $0x1,%eax
801008b2:	a3 08 20 11 80       	mov    %eax,0x80112008
        consputc(BACKSPACE);
801008b7:	b8 00 01 00 00       	mov    $0x100,%eax
801008bc:	e8 37 fc ff ff       	call   801004f8 <consputc>
801008c1:	eb be                	jmp    80100881 <consoleintr+0x103>
  release(&cons.lock);
801008c3:	83 ec 0c             	sub    $0xc,%esp
801008c6:	68 20 a5 10 80       	push   $0x8010a520
801008cb:	e8 06 35 00 00       	call   80103dd6 <release>
  if (shutdown)
801008d0:	83 c4 10             	add    $0x10,%esp
801008d3:	85 ff                	test   %edi,%edi
801008d5:	75 0e                	jne    801008e5 <consoleintr+0x167>
  if(doprocdump) {
801008d7:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
801008db:	75 0f                	jne    801008ec <consoleintr+0x16e>
}
801008dd:	8d 65 f4             	lea    -0xc(%ebp),%esp
801008e0:	5b                   	pop    %ebx
801008e1:	5e                   	pop    %esi
801008e2:	5f                   	pop    %edi
801008e3:	5d                   	pop    %ebp
801008e4:	c3                   	ret    
    do_shutdown();
801008e5:	e8 6f fe ff ff       	call   80100759 <do_shutdown>
801008ea:	eb eb                	jmp    801008d7 <consoleintr+0x159>
    procdump();  // now call procdump() wo. cons.lock held
801008ec:	e8 6d 31 00 00       	call   80103a5e <procdump>
}
801008f1:	eb ea                	jmp    801008dd <consoleintr+0x15f>

801008f3 <consoleinit>:

void
consoleinit(void)
{
801008f3:	f3 0f 1e fb          	endbr32 
801008f7:	55                   	push   %ebp
801008f8:	89 e5                	mov    %esp,%ebp
801008fa:	83 ec 10             	sub    $0x10,%esp
  initlock(&cons.lock, "console");
801008fd:	68 dc 66 10 80       	push   $0x801066dc
80100902:	68 20 a5 10 80       	push   $0x8010a520
80100907:	e8 11 33 00 00       	call   80103c1d <initlock>

  devsw[CONSOLE].write = consolewrite;
8010090c:	c7 05 cc 29 11 80 c6 	movl   $0x801005c6,0x801129cc
80100913:	05 10 80 
  devsw[CONSOLE].read = consoleread;
80100916:	c7 05 c8 29 11 80 78 	movl   $0x80100278,0x801129c8
8010091d:	02 10 80 
  cons.locking = 1;
80100920:	c7 05 54 a5 10 80 01 	movl   $0x1,0x8010a554
80100927:	00 00 00 

  ioapicenable(IRQ_KBD, 0);
8010092a:	83 c4 08             	add    $0x8,%esp
8010092d:	6a 00                	push   $0x0
8010092f:	6a 01                	push   $0x1
80100931:	e8 02 17 00 00       	call   80102038 <ioapicenable>
}
80100936:	83 c4 10             	add    $0x10,%esp
80100939:	c9                   	leave  
8010093a:	c3                   	ret    

8010093b <exec>:
#include "elf.h"


int
exec(char *path, char **argv)
{
8010093b:	f3 0f 1e fb          	endbr32 
8010093f:	55                   	push   %ebp
80100940:	89 e5                	mov    %esp,%ebp
80100942:	57                   	push   %edi
80100943:	56                   	push   %esi
80100944:	53                   	push   %ebx
80100945:	81 ec 0c 01 00 00    	sub    $0x10c,%esp
  uint argc, sz, sp, ustack[3+MAXARG+1];
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pde_t *pgdir, *oldpgdir;
  struct proc *curproc = myproc();
8010094b:	e8 ca 29 00 00       	call   8010331a <myproc>
80100950:	89 85 ec fe ff ff    	mov    %eax,-0x114(%ebp)

  begin_op();
80100956:	e8 31 1f 00 00       	call   8010288c <begin_op>

  if((ip = namei(path)) == 0){
8010095b:	83 ec 0c             	sub    $0xc,%esp
8010095e:	ff 75 08             	pushl  0x8(%ebp)
80100961:	e8 26 13 00 00       	call   80101c8c <namei>
80100966:	83 c4 10             	add    $0x10,%esp
80100969:	85 c0                	test   %eax,%eax
8010096b:	74 56                	je     801009c3 <exec+0x88>
8010096d:	89 c3                	mov    %eax,%ebx
#ifndef PDX_XV6
    cprintf("exec: fail\n");
#endif
    return -1;
  }
  ilock(ip);
8010096f:	83 ec 0c             	sub    $0xc,%esp
80100972:	50                   	push   %eax
80100973:	e8 8f 0c 00 00       	call   80101607 <ilock>
  pgdir = 0;

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) != sizeof(elf))
80100978:	6a 34                	push   $0x34
8010097a:	6a 00                	push   $0x0
8010097c:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
80100982:	50                   	push   %eax
80100983:	53                   	push   %ebx
80100984:	e8 84 0e 00 00       	call   8010180d <readi>
80100989:	83 c4 20             	add    $0x20,%esp
8010098c:	83 f8 34             	cmp    $0x34,%eax
8010098f:	75 0c                	jne    8010099d <exec+0x62>
    goto bad;
  if(elf.magic != ELF_MAGIC)
80100991:	81 bd 24 ff ff ff 7f 	cmpl   $0x464c457f,-0xdc(%ebp)
80100998:	45 4c 46 
8010099b:	74 32                	je     801009cf <exec+0x94>
  return 0;

bad:
  if(pgdir)
    freevm(pgdir);
  if(ip){
8010099d:	85 db                	test   %ebx,%ebx
8010099f:	0f 84 b9 02 00 00    	je     80100c5e <exec+0x323>
    iunlockput(ip);
801009a5:	83 ec 0c             	sub    $0xc,%esp
801009a8:	53                   	push   %ebx
801009a9:	e8 0c 0e 00 00       	call   801017ba <iunlockput>
    end_op();
801009ae:	e8 57 1f 00 00       	call   8010290a <end_op>
801009b3:	83 c4 10             	add    $0x10,%esp
  }
  return -1;
801009b6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801009bb:	8d 65 f4             	lea    -0xc(%ebp),%esp
801009be:	5b                   	pop    %ebx
801009bf:	5e                   	pop    %esi
801009c0:	5f                   	pop    %edi
801009c1:	5d                   	pop    %ebp
801009c2:	c3                   	ret    
    end_op();
801009c3:	e8 42 1f 00 00       	call   8010290a <end_op>
    return -1;
801009c8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801009cd:	eb ec                	jmp    801009bb <exec+0x80>
  if((pgdir = setupkvm()) == 0)
801009cf:	e8 2c 5a 00 00       	call   80106400 <setupkvm>
801009d4:	89 85 f0 fe ff ff    	mov    %eax,-0x110(%ebp)
801009da:	85 c0                	test   %eax,%eax
801009dc:	0f 84 09 01 00 00    	je     80100aeb <exec+0x1b0>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
801009e2:	8b 85 40 ff ff ff    	mov    -0xc0(%ebp),%eax
  sz = 0;
801009e8:	bf 00 00 00 00       	mov    $0x0,%edi
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
801009ed:	be 00 00 00 00       	mov    $0x0,%esi
801009f2:	eb 0c                	jmp    80100a00 <exec+0xc5>
801009f4:	83 c6 01             	add    $0x1,%esi
801009f7:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
801009fd:	83 c0 20             	add    $0x20,%eax
80100a00:	0f b7 95 50 ff ff ff 	movzwl -0xb0(%ebp),%edx
80100a07:	39 f2                	cmp    %esi,%edx
80100a09:	0f 8e 98 00 00 00    	jle    80100aa7 <exec+0x16c>
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
80100a0f:	89 85 f4 fe ff ff    	mov    %eax,-0x10c(%ebp)
80100a15:	6a 20                	push   $0x20
80100a17:	50                   	push   %eax
80100a18:	8d 85 04 ff ff ff    	lea    -0xfc(%ebp),%eax
80100a1e:	50                   	push   %eax
80100a1f:	53                   	push   %ebx
80100a20:	e8 e8 0d 00 00       	call   8010180d <readi>
80100a25:	83 c4 10             	add    $0x10,%esp
80100a28:	83 f8 20             	cmp    $0x20,%eax
80100a2b:	0f 85 ba 00 00 00    	jne    80100aeb <exec+0x1b0>
    if(ph.type != ELF_PROG_LOAD)
80100a31:	83 bd 04 ff ff ff 01 	cmpl   $0x1,-0xfc(%ebp)
80100a38:	75 ba                	jne    801009f4 <exec+0xb9>
    if(ph.memsz < ph.filesz)
80100a3a:	8b 85 18 ff ff ff    	mov    -0xe8(%ebp),%eax
80100a40:	3b 85 14 ff ff ff    	cmp    -0xec(%ebp),%eax
80100a46:	0f 82 9f 00 00 00    	jb     80100aeb <exec+0x1b0>
    if(ph.vaddr + ph.memsz < ph.vaddr)
80100a4c:	03 85 0c ff ff ff    	add    -0xf4(%ebp),%eax
80100a52:	0f 82 93 00 00 00    	jb     80100aeb <exec+0x1b0>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
80100a58:	83 ec 04             	sub    $0x4,%esp
80100a5b:	50                   	push   %eax
80100a5c:	57                   	push   %edi
80100a5d:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
80100a63:	e8 37 58 00 00       	call   8010629f <allocuvm>
80100a68:	89 c7                	mov    %eax,%edi
80100a6a:	83 c4 10             	add    $0x10,%esp
80100a6d:	85 c0                	test   %eax,%eax
80100a6f:	74 7a                	je     80100aeb <exec+0x1b0>
    if(ph.vaddr % PGSIZE != 0)
80100a71:	8b 85 0c ff ff ff    	mov    -0xf4(%ebp),%eax
80100a77:	a9 ff 0f 00 00       	test   $0xfff,%eax
80100a7c:	75 6d                	jne    80100aeb <exec+0x1b0>
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
80100a7e:	83 ec 0c             	sub    $0xc,%esp
80100a81:	ff b5 14 ff ff ff    	pushl  -0xec(%ebp)
80100a87:	ff b5 08 ff ff ff    	pushl  -0xf8(%ebp)
80100a8d:	53                   	push   %ebx
80100a8e:	50                   	push   %eax
80100a8f:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
80100a95:	e8 d0 56 00 00       	call   8010616a <loaduvm>
80100a9a:	83 c4 20             	add    $0x20,%esp
80100a9d:	85 c0                	test   %eax,%eax
80100a9f:	0f 89 4f ff ff ff    	jns    801009f4 <exec+0xb9>
80100aa5:	eb 44                	jmp    80100aeb <exec+0x1b0>
  iunlockput(ip);
80100aa7:	83 ec 0c             	sub    $0xc,%esp
80100aaa:	53                   	push   %ebx
80100aab:	e8 0a 0d 00 00       	call   801017ba <iunlockput>
  end_op();
80100ab0:	e8 55 1e 00 00       	call   8010290a <end_op>
  sz = PGROUNDUP(sz);
80100ab5:	8d 87 ff 0f 00 00    	lea    0xfff(%edi),%eax
80100abb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100ac0:	83 c4 0c             	add    $0xc,%esp
80100ac3:	8d 90 00 20 00 00    	lea    0x2000(%eax),%edx
80100ac9:	52                   	push   %edx
80100aca:	50                   	push   %eax
80100acb:	8b bd f0 fe ff ff    	mov    -0x110(%ebp),%edi
80100ad1:	57                   	push   %edi
80100ad2:	e8 c8 57 00 00       	call   8010629f <allocuvm>
80100ad7:	89 c6                	mov    %eax,%esi
80100ad9:	89 85 f4 fe ff ff    	mov    %eax,-0x10c(%ebp)
80100adf:	83 c4 10             	add    $0x10,%esp
80100ae2:	85 c0                	test   %eax,%eax
80100ae4:	75 24                	jne    80100b0a <exec+0x1cf>
  ip = 0;
80100ae6:	bb 00 00 00 00       	mov    $0x0,%ebx
  if(pgdir)
80100aeb:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
80100af1:	85 c0                	test   %eax,%eax
80100af3:	0f 84 a4 fe ff ff    	je     8010099d <exec+0x62>
    freevm(pgdir);
80100af9:	83 ec 0c             	sub    $0xc,%esp
80100afc:	50                   	push   %eax
80100afd:	e8 8a 58 00 00       	call   8010638c <freevm>
80100b02:	83 c4 10             	add    $0x10,%esp
80100b05:	e9 93 fe ff ff       	jmp    8010099d <exec+0x62>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100b0a:	8d 80 00 e0 ff ff    	lea    -0x2000(%eax),%eax
80100b10:	83 ec 08             	sub    $0x8,%esp
80100b13:	50                   	push   %eax
80100b14:	57                   	push   %edi
80100b15:	e8 73 59 00 00       	call   8010648d <clearpteu>
  for(argc = 0; argv[argc]; argc++) {
80100b1a:	83 c4 10             	add    $0x10,%esp
80100b1d:	bf 00 00 00 00       	mov    $0x0,%edi
80100b22:	8b 45 0c             	mov    0xc(%ebp),%eax
80100b25:	8d 1c b8             	lea    (%eax,%edi,4),%ebx
80100b28:	8b 03                	mov    (%ebx),%eax
80100b2a:	85 c0                	test   %eax,%eax
80100b2c:	74 4d                	je     80100b7b <exec+0x240>
    if(argc >= MAXARG)
80100b2e:	83 ff 1f             	cmp    $0x1f,%edi
80100b31:	0f 87 13 01 00 00    	ja     80100c4a <exec+0x30f>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
80100b37:	83 ec 0c             	sub    $0xc,%esp
80100b3a:	50                   	push   %eax
80100b3b:	e8 a2 34 00 00       	call   80103fe2 <strlen>
80100b40:	29 c6                	sub    %eax,%esi
80100b42:	83 ee 01             	sub    $0x1,%esi
80100b45:	83 e6 fc             	and    $0xfffffffc,%esi
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100b48:	83 c4 04             	add    $0x4,%esp
80100b4b:	ff 33                	pushl  (%ebx)
80100b4d:	e8 90 34 00 00       	call   80103fe2 <strlen>
80100b52:	83 c0 01             	add    $0x1,%eax
80100b55:	50                   	push   %eax
80100b56:	ff 33                	pushl  (%ebx)
80100b58:	56                   	push   %esi
80100b59:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
80100b5f:	e8 77 5a 00 00       	call   801065db <copyout>
80100b64:	83 c4 20             	add    $0x20,%esp
80100b67:	85 c0                	test   %eax,%eax
80100b69:	0f 88 e5 00 00 00    	js     80100c54 <exec+0x319>
    ustack[3+argc] = sp;
80100b6f:	89 b4 bd 64 ff ff ff 	mov    %esi,-0x9c(%ebp,%edi,4)
  for(argc = 0; argv[argc]; argc++) {
80100b76:	83 c7 01             	add    $0x1,%edi
80100b79:	eb a7                	jmp    80100b22 <exec+0x1e7>
80100b7b:	89 f1                	mov    %esi,%ecx
80100b7d:	89 c3                	mov    %eax,%ebx
  ustack[3+argc] = 0;
80100b7f:	c7 84 bd 64 ff ff ff 	movl   $0x0,-0x9c(%ebp,%edi,4)
80100b86:	00 00 00 00 
  ustack[0] = 0xffffffff;  // fake return PC
80100b8a:	c7 85 58 ff ff ff ff 	movl   $0xffffffff,-0xa8(%ebp)
80100b91:	ff ff ff 
  ustack[1] = argc;
80100b94:	89 bd 5c ff ff ff    	mov    %edi,-0xa4(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
80100b9a:	8d 04 bd 04 00 00 00 	lea    0x4(,%edi,4),%eax
80100ba1:	89 f2                	mov    %esi,%edx
80100ba3:	29 c2                	sub    %eax,%edx
80100ba5:	89 95 60 ff ff ff    	mov    %edx,-0xa0(%ebp)
  sp -= (3+argc+1) * 4;
80100bab:	8d 04 bd 10 00 00 00 	lea    0x10(,%edi,4),%eax
80100bb2:	29 c1                	sub    %eax,%ecx
80100bb4:	89 ce                	mov    %ecx,%esi
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
80100bb6:	50                   	push   %eax
80100bb7:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
80100bbd:	50                   	push   %eax
80100bbe:	51                   	push   %ecx
80100bbf:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
80100bc5:	e8 11 5a 00 00       	call   801065db <copyout>
80100bca:	83 c4 10             	add    $0x10,%esp
80100bcd:	85 c0                	test   %eax,%eax
80100bcf:	0f 88 16 ff ff ff    	js     80100aeb <exec+0x1b0>
  for(last=s=path; *s; s++)
80100bd5:	8b 55 08             	mov    0x8(%ebp),%edx
80100bd8:	89 d0                	mov    %edx,%eax
80100bda:	eb 03                	jmp    80100bdf <exec+0x2a4>
80100bdc:	83 c0 01             	add    $0x1,%eax
80100bdf:	0f b6 08             	movzbl (%eax),%ecx
80100be2:	84 c9                	test   %cl,%cl
80100be4:	74 0a                	je     80100bf0 <exec+0x2b5>
    if(*s == '/')
80100be6:	80 f9 2f             	cmp    $0x2f,%cl
80100be9:	75 f1                	jne    80100bdc <exec+0x2a1>
      last = s+1;
80100beb:	8d 50 01             	lea    0x1(%eax),%edx
80100bee:	eb ec                	jmp    80100bdc <exec+0x2a1>
  safestrcpy(curproc->name, last, sizeof(curproc->name));
80100bf0:	8b bd ec fe ff ff    	mov    -0x114(%ebp),%edi
80100bf6:	89 f8                	mov    %edi,%eax
80100bf8:	83 c0 6c             	add    $0x6c,%eax
80100bfb:	83 ec 04             	sub    $0x4,%esp
80100bfe:	6a 10                	push   $0x10
80100c00:	52                   	push   %edx
80100c01:	50                   	push   %eax
80100c02:	e8 9a 33 00 00       	call   80103fa1 <safestrcpy>
  oldpgdir = curproc->pgdir;
80100c07:	8b 5f 04             	mov    0x4(%edi),%ebx
  curproc->pgdir = pgdir;
80100c0a:	8b 8d f0 fe ff ff    	mov    -0x110(%ebp),%ecx
80100c10:	89 4f 04             	mov    %ecx,0x4(%edi)
  curproc->sz = sz;
80100c13:	8b 8d f4 fe ff ff    	mov    -0x10c(%ebp),%ecx
80100c19:	89 0f                	mov    %ecx,(%edi)
  curproc->tf->eip = elf.entry;  // main
80100c1b:	8b 47 18             	mov    0x18(%edi),%eax
80100c1e:	8b 95 3c ff ff ff    	mov    -0xc4(%ebp),%edx
80100c24:	89 50 38             	mov    %edx,0x38(%eax)
  curproc->tf->esp = sp;
80100c27:	8b 47 18             	mov    0x18(%edi),%eax
80100c2a:	89 70 44             	mov    %esi,0x44(%eax)
  switchuvm(curproc);
80100c2d:	89 3c 24             	mov    %edi,(%esp)
80100c30:	e8 ac 53 00 00       	call   80105fe1 <switchuvm>
  freevm(oldpgdir);
80100c35:	89 1c 24             	mov    %ebx,(%esp)
80100c38:	e8 4f 57 00 00       	call   8010638c <freevm>
  return 0;
80100c3d:	83 c4 10             	add    $0x10,%esp
80100c40:	b8 00 00 00 00       	mov    $0x0,%eax
80100c45:	e9 71 fd ff ff       	jmp    801009bb <exec+0x80>
  ip = 0;
80100c4a:	bb 00 00 00 00       	mov    $0x0,%ebx
80100c4f:	e9 97 fe ff ff       	jmp    80100aeb <exec+0x1b0>
80100c54:	bb 00 00 00 00       	mov    $0x0,%ebx
80100c59:	e9 8d fe ff ff       	jmp    80100aeb <exec+0x1b0>
  return -1;
80100c5e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100c63:	e9 53 fd ff ff       	jmp    801009bb <exec+0x80>

80100c68 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
80100c68:	f3 0f 1e fb          	endbr32 
80100c6c:	55                   	push   %ebp
80100c6d:	89 e5                	mov    %esp,%ebp
80100c6f:	83 ec 10             	sub    $0x10,%esp
  initlock(&ftable.lock, "ftable");
80100c72:	68 f5 66 10 80       	push   $0x801066f5
80100c77:	68 20 20 11 80       	push   $0x80112020
80100c7c:	e8 9c 2f 00 00       	call   80103c1d <initlock>
}
80100c81:	83 c4 10             	add    $0x10,%esp
80100c84:	c9                   	leave  
80100c85:	c3                   	ret    

80100c86 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
80100c86:	f3 0f 1e fb          	endbr32 
80100c8a:	55                   	push   %ebp
80100c8b:	89 e5                	mov    %esp,%ebp
80100c8d:	53                   	push   %ebx
80100c8e:	83 ec 10             	sub    $0x10,%esp
  struct file *f;

  acquire(&ftable.lock);
80100c91:	68 20 20 11 80       	push   $0x80112020
80100c96:	e8 d2 30 00 00       	call   80103d6d <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100c9b:	83 c4 10             	add    $0x10,%esp
80100c9e:	bb 54 20 11 80       	mov    $0x80112054,%ebx
80100ca3:	eb 03                	jmp    80100ca8 <filealloc+0x22>
80100ca5:	83 c3 18             	add    $0x18,%ebx
80100ca8:	81 fb b4 29 11 80    	cmp    $0x801129b4,%ebx
80100cae:	73 24                	jae    80100cd4 <filealloc+0x4e>
    if(f->ref == 0){
80100cb0:	83 7b 04 00          	cmpl   $0x0,0x4(%ebx)
80100cb4:	75 ef                	jne    80100ca5 <filealloc+0x1f>
      f->ref = 1;
80100cb6:	c7 43 04 01 00 00 00 	movl   $0x1,0x4(%ebx)
      release(&ftable.lock);
80100cbd:	83 ec 0c             	sub    $0xc,%esp
80100cc0:	68 20 20 11 80       	push   $0x80112020
80100cc5:	e8 0c 31 00 00       	call   80103dd6 <release>
      return f;
80100cca:	83 c4 10             	add    $0x10,%esp
    }
  }
  release(&ftable.lock);
  return 0;
}
80100ccd:	89 d8                	mov    %ebx,%eax
80100ccf:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100cd2:	c9                   	leave  
80100cd3:	c3                   	ret    
  release(&ftable.lock);
80100cd4:	83 ec 0c             	sub    $0xc,%esp
80100cd7:	68 20 20 11 80       	push   $0x80112020
80100cdc:	e8 f5 30 00 00       	call   80103dd6 <release>
  return 0;
80100ce1:	83 c4 10             	add    $0x10,%esp
80100ce4:	bb 00 00 00 00       	mov    $0x0,%ebx
80100ce9:	eb e2                	jmp    80100ccd <filealloc+0x47>

80100ceb <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
80100ceb:	f3 0f 1e fb          	endbr32 
80100cef:	55                   	push   %ebp
80100cf0:	89 e5                	mov    %esp,%ebp
80100cf2:	53                   	push   %ebx
80100cf3:	83 ec 10             	sub    $0x10,%esp
80100cf6:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&ftable.lock);
80100cf9:	68 20 20 11 80       	push   $0x80112020
80100cfe:	e8 6a 30 00 00       	call   80103d6d <acquire>
  if(f->ref < 1)
80100d03:	8b 43 04             	mov    0x4(%ebx),%eax
80100d06:	83 c4 10             	add    $0x10,%esp
80100d09:	85 c0                	test   %eax,%eax
80100d0b:	7e 1a                	jle    80100d27 <filedup+0x3c>
    panic("filedup");
  f->ref++;
80100d0d:	83 c0 01             	add    $0x1,%eax
80100d10:	89 43 04             	mov    %eax,0x4(%ebx)
  release(&ftable.lock);
80100d13:	83 ec 0c             	sub    $0xc,%esp
80100d16:	68 20 20 11 80       	push   $0x80112020
80100d1b:	e8 b6 30 00 00       	call   80103dd6 <release>
  return f;
}
80100d20:	89 d8                	mov    %ebx,%eax
80100d22:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100d25:	c9                   	leave  
80100d26:	c3                   	ret    
    panic("filedup");
80100d27:	83 ec 0c             	sub    $0xc,%esp
80100d2a:	68 fc 66 10 80       	push   $0x801066fc
80100d2f:	e8 28 f6 ff ff       	call   8010035c <panic>

80100d34 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
80100d34:	f3 0f 1e fb          	endbr32 
80100d38:	55                   	push   %ebp
80100d39:	89 e5                	mov    %esp,%ebp
80100d3b:	53                   	push   %ebx
80100d3c:	83 ec 30             	sub    $0x30,%esp
80100d3f:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct file ff;

  acquire(&ftable.lock);
80100d42:	68 20 20 11 80       	push   $0x80112020
80100d47:	e8 21 30 00 00       	call   80103d6d <acquire>
  if(f->ref < 1)
80100d4c:	8b 43 04             	mov    0x4(%ebx),%eax
80100d4f:	83 c4 10             	add    $0x10,%esp
80100d52:	85 c0                	test   %eax,%eax
80100d54:	7e 65                	jle    80100dbb <fileclose+0x87>
    panic("fileclose");
  if(--f->ref > 0){
80100d56:	83 e8 01             	sub    $0x1,%eax
80100d59:	89 43 04             	mov    %eax,0x4(%ebx)
80100d5c:	85 c0                	test   %eax,%eax
80100d5e:	7f 68                	jg     80100dc8 <fileclose+0x94>
    release(&ftable.lock);
    return;
  }
  ff = *f;
80100d60:	8b 03                	mov    (%ebx),%eax
80100d62:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100d65:	8b 43 08             	mov    0x8(%ebx),%eax
80100d68:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100d6b:	8b 43 0c             	mov    0xc(%ebx),%eax
80100d6e:	89 45 ec             	mov    %eax,-0x14(%ebp)
80100d71:	8b 43 10             	mov    0x10(%ebx),%eax
80100d74:	89 45 f0             	mov    %eax,-0x10(%ebp)
  f->ref = 0;
80100d77:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
  f->type = FD_NONE;
80100d7e:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  release(&ftable.lock);
80100d84:	83 ec 0c             	sub    $0xc,%esp
80100d87:	68 20 20 11 80       	push   $0x80112020
80100d8c:	e8 45 30 00 00       	call   80103dd6 <release>

  if(ff.type == FD_PIPE)
80100d91:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d94:	83 c4 10             	add    $0x10,%esp
80100d97:	83 f8 01             	cmp    $0x1,%eax
80100d9a:	74 41                	je     80100ddd <fileclose+0xa9>
    pipeclose(ff.pipe, ff.writable);
  else if(ff.type == FD_INODE){
80100d9c:	83 f8 02             	cmp    $0x2,%eax
80100d9f:	75 37                	jne    80100dd8 <fileclose+0xa4>
    begin_op();
80100da1:	e8 e6 1a 00 00       	call   8010288c <begin_op>
    iput(ff.ip);
80100da6:	83 ec 0c             	sub    $0xc,%esp
80100da9:	ff 75 f0             	pushl  -0x10(%ebp)
80100dac:	e8 65 09 00 00       	call   80101716 <iput>
    end_op();
80100db1:	e8 54 1b 00 00       	call   8010290a <end_op>
80100db6:	83 c4 10             	add    $0x10,%esp
80100db9:	eb 1d                	jmp    80100dd8 <fileclose+0xa4>
    panic("fileclose");
80100dbb:	83 ec 0c             	sub    $0xc,%esp
80100dbe:	68 04 67 10 80       	push   $0x80106704
80100dc3:	e8 94 f5 ff ff       	call   8010035c <panic>
    release(&ftable.lock);
80100dc8:	83 ec 0c             	sub    $0xc,%esp
80100dcb:	68 20 20 11 80       	push   $0x80112020
80100dd0:	e8 01 30 00 00       	call   80103dd6 <release>
    return;
80100dd5:	83 c4 10             	add    $0x10,%esp
  }
}
80100dd8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100ddb:	c9                   	leave  
80100ddc:	c3                   	ret    
    pipeclose(ff.pipe, ff.writable);
80100ddd:	83 ec 08             	sub    $0x8,%esp
80100de0:	0f be 45 e9          	movsbl -0x17(%ebp),%eax
80100de4:	50                   	push   %eax
80100de5:	ff 75 ec             	pushl  -0x14(%ebp)
80100de8:	e8 32 21 00 00       	call   80102f1f <pipeclose>
80100ded:	83 c4 10             	add    $0x10,%esp
80100df0:	eb e6                	jmp    80100dd8 <fileclose+0xa4>

80100df2 <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
80100df2:	f3 0f 1e fb          	endbr32 
80100df6:	55                   	push   %ebp
80100df7:	89 e5                	mov    %esp,%ebp
80100df9:	53                   	push   %ebx
80100dfa:	83 ec 04             	sub    $0x4,%esp
80100dfd:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(f->type == FD_INODE){
80100e00:	83 3b 02             	cmpl   $0x2,(%ebx)
80100e03:	75 31                	jne    80100e36 <filestat+0x44>
    ilock(f->ip);
80100e05:	83 ec 0c             	sub    $0xc,%esp
80100e08:	ff 73 10             	pushl  0x10(%ebx)
80100e0b:	e8 f7 07 00 00       	call   80101607 <ilock>
    stati(f->ip, st);
80100e10:	83 c4 08             	add    $0x8,%esp
80100e13:	ff 75 0c             	pushl  0xc(%ebp)
80100e16:	ff 73 10             	pushl  0x10(%ebx)
80100e19:	e8 c0 09 00 00       	call   801017de <stati>
    iunlock(f->ip);
80100e1e:	83 c4 04             	add    $0x4,%esp
80100e21:	ff 73 10             	pushl  0x10(%ebx)
80100e24:	e8 a4 08 00 00       	call   801016cd <iunlock>
    return 0;
80100e29:	83 c4 10             	add    $0x10,%esp
80100e2c:	b8 00 00 00 00       	mov    $0x0,%eax
  }
  return -1;
}
80100e31:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100e34:	c9                   	leave  
80100e35:	c3                   	ret    
  return -1;
80100e36:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100e3b:	eb f4                	jmp    80100e31 <filestat+0x3f>

80100e3d <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
80100e3d:	f3 0f 1e fb          	endbr32 
80100e41:	55                   	push   %ebp
80100e42:	89 e5                	mov    %esp,%ebp
80100e44:	56                   	push   %esi
80100e45:	53                   	push   %ebx
80100e46:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;

  if(f->readable == 0)
80100e49:	80 7b 08 00          	cmpb   $0x0,0x8(%ebx)
80100e4d:	74 70                	je     80100ebf <fileread+0x82>
    return -1;
  if(f->type == FD_PIPE)
80100e4f:	8b 03                	mov    (%ebx),%eax
80100e51:	83 f8 01             	cmp    $0x1,%eax
80100e54:	74 44                	je     80100e9a <fileread+0x5d>
    return piperead(f->pipe, addr, n);
  if(f->type == FD_INODE){
80100e56:	83 f8 02             	cmp    $0x2,%eax
80100e59:	75 57                	jne    80100eb2 <fileread+0x75>
    ilock(f->ip);
80100e5b:	83 ec 0c             	sub    $0xc,%esp
80100e5e:	ff 73 10             	pushl  0x10(%ebx)
80100e61:	e8 a1 07 00 00       	call   80101607 <ilock>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
80100e66:	ff 75 10             	pushl  0x10(%ebp)
80100e69:	ff 73 14             	pushl  0x14(%ebx)
80100e6c:	ff 75 0c             	pushl  0xc(%ebp)
80100e6f:	ff 73 10             	pushl  0x10(%ebx)
80100e72:	e8 96 09 00 00       	call   8010180d <readi>
80100e77:	89 c6                	mov    %eax,%esi
80100e79:	83 c4 20             	add    $0x20,%esp
80100e7c:	85 c0                	test   %eax,%eax
80100e7e:	7e 03                	jle    80100e83 <fileread+0x46>
      f->off += r;
80100e80:	01 43 14             	add    %eax,0x14(%ebx)
    iunlock(f->ip);
80100e83:	83 ec 0c             	sub    $0xc,%esp
80100e86:	ff 73 10             	pushl  0x10(%ebx)
80100e89:	e8 3f 08 00 00       	call   801016cd <iunlock>
    return r;
80100e8e:	83 c4 10             	add    $0x10,%esp
  }
  panic("fileread");
}
80100e91:	89 f0                	mov    %esi,%eax
80100e93:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100e96:	5b                   	pop    %ebx
80100e97:	5e                   	pop    %esi
80100e98:	5d                   	pop    %ebp
80100e99:	c3                   	ret    
    return piperead(f->pipe, addr, n);
80100e9a:	83 ec 04             	sub    $0x4,%esp
80100e9d:	ff 75 10             	pushl  0x10(%ebp)
80100ea0:	ff 75 0c             	pushl  0xc(%ebp)
80100ea3:	ff 73 0c             	pushl  0xc(%ebx)
80100ea6:	e8 ce 21 00 00       	call   80103079 <piperead>
80100eab:	89 c6                	mov    %eax,%esi
80100ead:	83 c4 10             	add    $0x10,%esp
80100eb0:	eb df                	jmp    80100e91 <fileread+0x54>
  panic("fileread");
80100eb2:	83 ec 0c             	sub    $0xc,%esp
80100eb5:	68 0e 67 10 80       	push   $0x8010670e
80100eba:	e8 9d f4 ff ff       	call   8010035c <panic>
    return -1;
80100ebf:	be ff ff ff ff       	mov    $0xffffffff,%esi
80100ec4:	eb cb                	jmp    80100e91 <fileread+0x54>

80100ec6 <filewrite>:

//PAGEBREAK!
// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
80100ec6:	f3 0f 1e fb          	endbr32 
80100eca:	55                   	push   %ebp
80100ecb:	89 e5                	mov    %esp,%ebp
80100ecd:	57                   	push   %edi
80100ece:	56                   	push   %esi
80100ecf:	53                   	push   %ebx
80100ed0:	83 ec 1c             	sub    $0x1c,%esp
80100ed3:	8b 75 08             	mov    0x8(%ebp),%esi
  int r;

  if(f->writable == 0)
80100ed6:	80 7e 09 00          	cmpb   $0x0,0x9(%esi)
80100eda:	0f 84 cc 00 00 00    	je     80100fac <filewrite+0xe6>
    return -1;
  if(f->type == FD_PIPE)
80100ee0:	8b 06                	mov    (%esi),%eax
80100ee2:	83 f8 01             	cmp    $0x1,%eax
80100ee5:	74 10                	je     80100ef7 <filewrite+0x31>
    return pipewrite(f->pipe, addr, n);
  if(f->type == FD_INODE){
80100ee7:	83 f8 02             	cmp    $0x2,%eax
80100eea:	0f 85 af 00 00 00    	jne    80100f9f <filewrite+0xd9>
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * 512;
    int i = 0;
80100ef0:	bf 00 00 00 00       	mov    $0x0,%edi
80100ef5:	eb 67                	jmp    80100f5e <filewrite+0x98>
    return pipewrite(f->pipe, addr, n);
80100ef7:	83 ec 04             	sub    $0x4,%esp
80100efa:	ff 75 10             	pushl  0x10(%ebp)
80100efd:	ff 75 0c             	pushl  0xc(%ebp)
80100f00:	ff 76 0c             	pushl  0xc(%esi)
80100f03:	e8 a7 20 00 00       	call   80102faf <pipewrite>
80100f08:	83 c4 10             	add    $0x10,%esp
80100f0b:	e9 82 00 00 00       	jmp    80100f92 <filewrite+0xcc>
    while(i < n){
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
80100f10:	e8 77 19 00 00       	call   8010288c <begin_op>
      ilock(f->ip);
80100f15:	83 ec 0c             	sub    $0xc,%esp
80100f18:	ff 76 10             	pushl  0x10(%esi)
80100f1b:	e8 e7 06 00 00       	call   80101607 <ilock>
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
80100f20:	ff 75 e4             	pushl  -0x1c(%ebp)
80100f23:	ff 76 14             	pushl  0x14(%esi)
80100f26:	89 f8                	mov    %edi,%eax
80100f28:	03 45 0c             	add    0xc(%ebp),%eax
80100f2b:	50                   	push   %eax
80100f2c:	ff 76 10             	pushl  0x10(%esi)
80100f2f:	e8 da 09 00 00       	call   8010190e <writei>
80100f34:	89 c3                	mov    %eax,%ebx
80100f36:	83 c4 20             	add    $0x20,%esp
80100f39:	85 c0                	test   %eax,%eax
80100f3b:	7e 03                	jle    80100f40 <filewrite+0x7a>
        f->off += r;
80100f3d:	01 46 14             	add    %eax,0x14(%esi)
      iunlock(f->ip);
80100f40:	83 ec 0c             	sub    $0xc,%esp
80100f43:	ff 76 10             	pushl  0x10(%esi)
80100f46:	e8 82 07 00 00       	call   801016cd <iunlock>
      end_op();
80100f4b:	e8 ba 19 00 00       	call   8010290a <end_op>

      if(r < 0)
80100f50:	83 c4 10             	add    $0x10,%esp
80100f53:	85 db                	test   %ebx,%ebx
80100f55:	78 31                	js     80100f88 <filewrite+0xc2>
        break;
      if(r != n1)
80100f57:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
80100f5a:	75 1f                	jne    80100f7b <filewrite+0xb5>
        panic("short filewrite");
      i += r;
80100f5c:	01 df                	add    %ebx,%edi
    while(i < n){
80100f5e:	3b 7d 10             	cmp    0x10(%ebp),%edi
80100f61:	7d 25                	jge    80100f88 <filewrite+0xc2>
      int n1 = n - i;
80100f63:	8b 45 10             	mov    0x10(%ebp),%eax
80100f66:	29 f8                	sub    %edi,%eax
80100f68:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      if(n1 > max)
80100f6b:	3d 00 06 00 00       	cmp    $0x600,%eax
80100f70:	7e 9e                	jle    80100f10 <filewrite+0x4a>
        n1 = max;
80100f72:	c7 45 e4 00 06 00 00 	movl   $0x600,-0x1c(%ebp)
80100f79:	eb 95                	jmp    80100f10 <filewrite+0x4a>
        panic("short filewrite");
80100f7b:	83 ec 0c             	sub    $0xc,%esp
80100f7e:	68 17 67 10 80       	push   $0x80106717
80100f83:	e8 d4 f3 ff ff       	call   8010035c <panic>
    }
    return i == n ? n : -1;
80100f88:	3b 7d 10             	cmp    0x10(%ebp),%edi
80100f8b:	74 0d                	je     80100f9a <filewrite+0xd4>
80100f8d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  panic("filewrite");
}
80100f92:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100f95:	5b                   	pop    %ebx
80100f96:	5e                   	pop    %esi
80100f97:	5f                   	pop    %edi
80100f98:	5d                   	pop    %ebp
80100f99:	c3                   	ret    
    return i == n ? n : -1;
80100f9a:	8b 45 10             	mov    0x10(%ebp),%eax
80100f9d:	eb f3                	jmp    80100f92 <filewrite+0xcc>
  panic("filewrite");
80100f9f:	83 ec 0c             	sub    $0xc,%esp
80100fa2:	68 1d 67 10 80       	push   $0x8010671d
80100fa7:	e8 b0 f3 ff ff       	call   8010035c <panic>
    return -1;
80100fac:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100fb1:	eb df                	jmp    80100f92 <filewrite+0xcc>

80100fb3 <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
80100fb3:	55                   	push   %ebp
80100fb4:	89 e5                	mov    %esp,%ebp
80100fb6:	57                   	push   %edi
80100fb7:	56                   	push   %esi
80100fb8:	53                   	push   %ebx
80100fb9:	83 ec 0c             	sub    $0xc,%esp
80100fbc:	89 d6                	mov    %edx,%esi
  char *s;
  int len;

  while(*path == '/')
80100fbe:	0f b6 10             	movzbl (%eax),%edx
80100fc1:	80 fa 2f             	cmp    $0x2f,%dl
80100fc4:	75 05                	jne    80100fcb <skipelem+0x18>
    path++;
80100fc6:	83 c0 01             	add    $0x1,%eax
80100fc9:	eb f3                	jmp    80100fbe <skipelem+0xb>
  if(*path == 0)
80100fcb:	84 d2                	test   %dl,%dl
80100fcd:	74 59                	je     80101028 <skipelem+0x75>
80100fcf:	89 c3                	mov    %eax,%ebx
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
80100fd1:	0f b6 13             	movzbl (%ebx),%edx
80100fd4:	80 fa 2f             	cmp    $0x2f,%dl
80100fd7:	0f 95 c1             	setne  %cl
80100fda:	84 d2                	test   %dl,%dl
80100fdc:	0f 95 c2             	setne  %dl
80100fdf:	84 d1                	test   %dl,%cl
80100fe1:	74 05                	je     80100fe8 <skipelem+0x35>
    path++;
80100fe3:	83 c3 01             	add    $0x1,%ebx
80100fe6:	eb e9                	jmp    80100fd1 <skipelem+0x1e>
  len = path - s;
80100fe8:	89 df                	mov    %ebx,%edi
80100fea:	29 c7                	sub    %eax,%edi
  if(len >= DIRSIZ)
80100fec:	83 ff 0d             	cmp    $0xd,%edi
80100fef:	7e 11                	jle    80101002 <skipelem+0x4f>
    memmove(name, s, DIRSIZ);
80100ff1:	83 ec 04             	sub    $0x4,%esp
80100ff4:	6a 0e                	push   $0xe
80100ff6:	50                   	push   %eax
80100ff7:	56                   	push   %esi
80100ff8:	e8 a4 2e 00 00       	call   80103ea1 <memmove>
80100ffd:	83 c4 10             	add    $0x10,%esp
80101000:	eb 17                	jmp    80101019 <skipelem+0x66>
  else {
    memmove(name, s, len);
80101002:	83 ec 04             	sub    $0x4,%esp
80101005:	57                   	push   %edi
80101006:	50                   	push   %eax
80101007:	56                   	push   %esi
80101008:	e8 94 2e 00 00       	call   80103ea1 <memmove>
    name[len] = 0;
8010100d:	c6 04 3e 00          	movb   $0x0,(%esi,%edi,1)
80101011:	83 c4 10             	add    $0x10,%esp
80101014:	eb 03                	jmp    80101019 <skipelem+0x66>
  }
  while(*path == '/')
    path++;
80101016:	83 c3 01             	add    $0x1,%ebx
  while(*path == '/')
80101019:	80 3b 2f             	cmpb   $0x2f,(%ebx)
8010101c:	74 f8                	je     80101016 <skipelem+0x63>
  return path;
}
8010101e:	89 d8                	mov    %ebx,%eax
80101020:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101023:	5b                   	pop    %ebx
80101024:	5e                   	pop    %esi
80101025:	5f                   	pop    %edi
80101026:	5d                   	pop    %ebp
80101027:	c3                   	ret    
    return 0;
80101028:	bb 00 00 00 00       	mov    $0x0,%ebx
8010102d:	eb ef                	jmp    8010101e <skipelem+0x6b>

8010102f <bzero>:
{
8010102f:	55                   	push   %ebp
80101030:	89 e5                	mov    %esp,%ebp
80101032:	53                   	push   %ebx
80101033:	83 ec 0c             	sub    $0xc,%esp
  bp = bread(dev, bno);
80101036:	52                   	push   %edx
80101037:	50                   	push   %eax
80101038:	e8 33 f1 ff ff       	call   80100170 <bread>
8010103d:	89 c3                	mov    %eax,%ebx
  memset(bp->data, 0, BSIZE);
8010103f:	8d 40 5c             	lea    0x5c(%eax),%eax
80101042:	83 c4 0c             	add    $0xc,%esp
80101045:	68 00 02 00 00       	push   $0x200
8010104a:	6a 00                	push   $0x0
8010104c:	50                   	push   %eax
8010104d:	e8 cf 2d 00 00       	call   80103e21 <memset>
  log_write(bp);
80101052:	89 1c 24             	mov    %ebx,(%esp)
80101055:	e8 63 19 00 00       	call   801029bd <log_write>
  brelse(bp);
8010105a:	89 1c 24             	mov    %ebx,(%esp)
8010105d:	e8 7f f1 ff ff       	call   801001e1 <brelse>
}
80101062:	83 c4 10             	add    $0x10,%esp
80101065:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101068:	c9                   	leave  
80101069:	c3                   	ret    

8010106a <balloc>:
{
8010106a:	55                   	push   %ebp
8010106b:	89 e5                	mov    %esp,%ebp
8010106d:	57                   	push   %edi
8010106e:	56                   	push   %esi
8010106f:	53                   	push   %ebx
80101070:	83 ec 1c             	sub    $0x1c,%esp
80101073:	89 45 d8             	mov    %eax,-0x28(%ebp)
  for(b = 0; b < sb.size; b += BPB){
80101076:	be 00 00 00 00       	mov    $0x0,%esi
8010107b:	eb 14                	jmp    80101091 <balloc+0x27>
    brelse(bp);
8010107d:	83 ec 0c             	sub    $0xc,%esp
80101080:	ff 75 e4             	pushl  -0x1c(%ebp)
80101083:	e8 59 f1 ff ff       	call   801001e1 <brelse>
  for(b = 0; b < sb.size; b += BPB){
80101088:	81 c6 00 10 00 00    	add    $0x1000,%esi
8010108e:	83 c4 10             	add    $0x10,%esp
80101091:	39 35 20 2a 11 80    	cmp    %esi,0x80112a20
80101097:	76 75                	jbe    8010110e <balloc+0xa4>
    bp = bread(dev, BBLOCK(b, sb));
80101099:	8d 86 ff 0f 00 00    	lea    0xfff(%esi),%eax
8010109f:	85 f6                	test   %esi,%esi
801010a1:	0f 49 c6             	cmovns %esi,%eax
801010a4:	c1 f8 0c             	sar    $0xc,%eax
801010a7:	83 ec 08             	sub    $0x8,%esp
801010aa:	03 05 38 2a 11 80    	add    0x80112a38,%eax
801010b0:	50                   	push   %eax
801010b1:	ff 75 d8             	pushl  -0x28(%ebp)
801010b4:	e8 b7 f0 ff ff       	call   80100170 <bread>
801010b9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
801010bc:	83 c4 10             	add    $0x10,%esp
801010bf:	b8 00 00 00 00       	mov    $0x0,%eax
801010c4:	3d ff 0f 00 00       	cmp    $0xfff,%eax
801010c9:	7f b2                	jg     8010107d <balloc+0x13>
801010cb:	8d 1c 06             	lea    (%esi,%eax,1),%ebx
801010ce:	89 5d e0             	mov    %ebx,-0x20(%ebp)
801010d1:	3b 1d 20 2a 11 80    	cmp    0x80112a20,%ebx
801010d7:	73 a4                	jae    8010107d <balloc+0x13>
      m = 1 << (bi % 8);
801010d9:	99                   	cltd   
801010da:	c1 ea 1d             	shr    $0x1d,%edx
801010dd:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
801010e0:	83 e1 07             	and    $0x7,%ecx
801010e3:	29 d1                	sub    %edx,%ecx
801010e5:	ba 01 00 00 00       	mov    $0x1,%edx
801010ea:	d3 e2                	shl    %cl,%edx
      if((bp->data[bi/8] & m) == 0){  // Is block free?
801010ec:	8d 48 07             	lea    0x7(%eax),%ecx
801010ef:	85 c0                	test   %eax,%eax
801010f1:	0f 49 c8             	cmovns %eax,%ecx
801010f4:	c1 f9 03             	sar    $0x3,%ecx
801010f7:	89 4d dc             	mov    %ecx,-0x24(%ebp)
801010fa:	8b 7d e4             	mov    -0x1c(%ebp),%edi
801010fd:	0f b6 4c 0f 5c       	movzbl 0x5c(%edi,%ecx,1),%ecx
80101102:	0f b6 f9             	movzbl %cl,%edi
80101105:	85 d7                	test   %edx,%edi
80101107:	74 12                	je     8010111b <balloc+0xb1>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
80101109:	83 c0 01             	add    $0x1,%eax
8010110c:	eb b6                	jmp    801010c4 <balloc+0x5a>
  panic("balloc: out of blocks");
8010110e:	83 ec 0c             	sub    $0xc,%esp
80101111:	68 27 67 10 80       	push   $0x80106727
80101116:	e8 41 f2 ff ff       	call   8010035c <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
8010111b:	09 ca                	or     %ecx,%edx
8010111d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101120:	8b 75 dc             	mov    -0x24(%ebp),%esi
80101123:	88 54 30 5c          	mov    %dl,0x5c(%eax,%esi,1)
        log_write(bp);
80101127:	83 ec 0c             	sub    $0xc,%esp
8010112a:	89 c6                	mov    %eax,%esi
8010112c:	50                   	push   %eax
8010112d:	e8 8b 18 00 00       	call   801029bd <log_write>
        brelse(bp);
80101132:	89 34 24             	mov    %esi,(%esp)
80101135:	e8 a7 f0 ff ff       	call   801001e1 <brelse>
        bzero(dev, b + bi);
8010113a:	89 da                	mov    %ebx,%edx
8010113c:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010113f:	e8 eb fe ff ff       	call   8010102f <bzero>
}
80101144:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101147:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010114a:	5b                   	pop    %ebx
8010114b:	5e                   	pop    %esi
8010114c:	5f                   	pop    %edi
8010114d:	5d                   	pop    %ebp
8010114e:	c3                   	ret    

8010114f <bmap>:
{
8010114f:	55                   	push   %ebp
80101150:	89 e5                	mov    %esp,%ebp
80101152:	57                   	push   %edi
80101153:	56                   	push   %esi
80101154:	53                   	push   %ebx
80101155:	83 ec 1c             	sub    $0x1c,%esp
80101158:	89 c3                	mov    %eax,%ebx
8010115a:	89 d7                	mov    %edx,%edi
  if(bn < NDIRECT){
8010115c:	83 fa 0b             	cmp    $0xb,%edx
8010115f:	76 45                	jbe    801011a6 <bmap+0x57>
  bn -= NDIRECT;
80101161:	8d 72 f4             	lea    -0xc(%edx),%esi
  if(bn < NINDIRECT){
80101164:	83 fe 7f             	cmp    $0x7f,%esi
80101167:	77 7f                	ja     801011e8 <bmap+0x99>
    if((addr = ip->addrs[NDIRECT]) == 0)
80101169:	8b 80 8c 00 00 00    	mov    0x8c(%eax),%eax
8010116f:	85 c0                	test   %eax,%eax
80101171:	74 4a                	je     801011bd <bmap+0x6e>
    bp = bread(ip->dev, addr);
80101173:	83 ec 08             	sub    $0x8,%esp
80101176:	50                   	push   %eax
80101177:	ff 33                	pushl  (%ebx)
80101179:	e8 f2 ef ff ff       	call   80100170 <bread>
8010117e:	89 c7                	mov    %eax,%edi
    if((addr = a[bn]) == 0){
80101180:	8d 44 b0 5c          	lea    0x5c(%eax,%esi,4),%eax
80101184:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80101187:	8b 30                	mov    (%eax),%esi
80101189:	83 c4 10             	add    $0x10,%esp
8010118c:	85 f6                	test   %esi,%esi
8010118e:	74 3c                	je     801011cc <bmap+0x7d>
    brelse(bp);
80101190:	83 ec 0c             	sub    $0xc,%esp
80101193:	57                   	push   %edi
80101194:	e8 48 f0 ff ff       	call   801001e1 <brelse>
    return addr;
80101199:	83 c4 10             	add    $0x10,%esp
}
8010119c:	89 f0                	mov    %esi,%eax
8010119e:	8d 65 f4             	lea    -0xc(%ebp),%esp
801011a1:	5b                   	pop    %ebx
801011a2:	5e                   	pop    %esi
801011a3:	5f                   	pop    %edi
801011a4:	5d                   	pop    %ebp
801011a5:	c3                   	ret    
    if((addr = ip->addrs[bn]) == 0)
801011a6:	8b 74 90 5c          	mov    0x5c(%eax,%edx,4),%esi
801011aa:	85 f6                	test   %esi,%esi
801011ac:	75 ee                	jne    8010119c <bmap+0x4d>
      ip->addrs[bn] = addr = balloc(ip->dev);
801011ae:	8b 00                	mov    (%eax),%eax
801011b0:	e8 b5 fe ff ff       	call   8010106a <balloc>
801011b5:	89 c6                	mov    %eax,%esi
801011b7:	89 44 bb 5c          	mov    %eax,0x5c(%ebx,%edi,4)
    return addr;
801011bb:	eb df                	jmp    8010119c <bmap+0x4d>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
801011bd:	8b 03                	mov    (%ebx),%eax
801011bf:	e8 a6 fe ff ff       	call   8010106a <balloc>
801011c4:	89 83 8c 00 00 00    	mov    %eax,0x8c(%ebx)
801011ca:	eb a7                	jmp    80101173 <bmap+0x24>
      a[bn] = addr = balloc(ip->dev);
801011cc:	8b 03                	mov    (%ebx),%eax
801011ce:	e8 97 fe ff ff       	call   8010106a <balloc>
801011d3:	89 c6                	mov    %eax,%esi
801011d5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801011d8:	89 30                	mov    %esi,(%eax)
      log_write(bp);
801011da:	83 ec 0c             	sub    $0xc,%esp
801011dd:	57                   	push   %edi
801011de:	e8 da 17 00 00       	call   801029bd <log_write>
801011e3:	83 c4 10             	add    $0x10,%esp
801011e6:	eb a8                	jmp    80101190 <bmap+0x41>
  panic("bmap: out of range");
801011e8:	83 ec 0c             	sub    $0xc,%esp
801011eb:	68 3d 67 10 80       	push   $0x8010673d
801011f0:	e8 67 f1 ff ff       	call   8010035c <panic>

801011f5 <iget>:
{
801011f5:	55                   	push   %ebp
801011f6:	89 e5                	mov    %esp,%ebp
801011f8:	57                   	push   %edi
801011f9:	56                   	push   %esi
801011fa:	53                   	push   %ebx
801011fb:	83 ec 28             	sub    $0x28,%esp
801011fe:	89 c7                	mov    %eax,%edi
80101200:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  acquire(&icache.lock);
80101203:	68 40 2a 11 80       	push   $0x80112a40
80101208:	e8 60 2b 00 00       	call   80103d6d <acquire>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
8010120d:	83 c4 10             	add    $0x10,%esp
  empty = 0;
80101210:	be 00 00 00 00       	mov    $0x0,%esi
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80101215:	bb 74 2a 11 80       	mov    $0x80112a74,%ebx
8010121a:	eb 0a                	jmp    80101226 <iget+0x31>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
8010121c:	85 f6                	test   %esi,%esi
8010121e:	74 3b                	je     8010125b <iget+0x66>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80101220:	81 c3 90 00 00 00    	add    $0x90,%ebx
80101226:	81 fb 94 46 11 80    	cmp    $0x80114694,%ebx
8010122c:	73 35                	jae    80101263 <iget+0x6e>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
8010122e:	8b 43 08             	mov    0x8(%ebx),%eax
80101231:	85 c0                	test   %eax,%eax
80101233:	7e e7                	jle    8010121c <iget+0x27>
80101235:	39 3b                	cmp    %edi,(%ebx)
80101237:	75 e3                	jne    8010121c <iget+0x27>
80101239:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
8010123c:	39 4b 04             	cmp    %ecx,0x4(%ebx)
8010123f:	75 db                	jne    8010121c <iget+0x27>
      ip->ref++;
80101241:	83 c0 01             	add    $0x1,%eax
80101244:	89 43 08             	mov    %eax,0x8(%ebx)
      release(&icache.lock);
80101247:	83 ec 0c             	sub    $0xc,%esp
8010124a:	68 40 2a 11 80       	push   $0x80112a40
8010124f:	e8 82 2b 00 00       	call   80103dd6 <release>
      return ip;
80101254:	83 c4 10             	add    $0x10,%esp
80101257:	89 de                	mov    %ebx,%esi
80101259:	eb 32                	jmp    8010128d <iget+0x98>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
8010125b:	85 c0                	test   %eax,%eax
8010125d:	75 c1                	jne    80101220 <iget+0x2b>
      empty = ip;
8010125f:	89 de                	mov    %ebx,%esi
80101261:	eb bd                	jmp    80101220 <iget+0x2b>
  if(empty == 0)
80101263:	85 f6                	test   %esi,%esi
80101265:	74 30                	je     80101297 <iget+0xa2>
  ip->dev = dev;
80101267:	89 3e                	mov    %edi,(%esi)
  ip->inum = inum;
80101269:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010126c:	89 46 04             	mov    %eax,0x4(%esi)
  ip->ref = 1;
8010126f:	c7 46 08 01 00 00 00 	movl   $0x1,0x8(%esi)
  ip->valid = 0;
80101276:	c7 46 4c 00 00 00 00 	movl   $0x0,0x4c(%esi)
  release(&icache.lock);
8010127d:	83 ec 0c             	sub    $0xc,%esp
80101280:	68 40 2a 11 80       	push   $0x80112a40
80101285:	e8 4c 2b 00 00       	call   80103dd6 <release>
  return ip;
8010128a:	83 c4 10             	add    $0x10,%esp
}
8010128d:	89 f0                	mov    %esi,%eax
8010128f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101292:	5b                   	pop    %ebx
80101293:	5e                   	pop    %esi
80101294:	5f                   	pop    %edi
80101295:	5d                   	pop    %ebp
80101296:	c3                   	ret    
    panic("iget: no inodes");
80101297:	83 ec 0c             	sub    $0xc,%esp
8010129a:	68 50 67 10 80       	push   $0x80106750
8010129f:	e8 b8 f0 ff ff       	call   8010035c <panic>

801012a4 <readsb>:
{
801012a4:	f3 0f 1e fb          	endbr32 
801012a8:	55                   	push   %ebp
801012a9:	89 e5                	mov    %esp,%ebp
801012ab:	53                   	push   %ebx
801012ac:	83 ec 0c             	sub    $0xc,%esp
  bp = bread(dev, 1);
801012af:	6a 01                	push   $0x1
801012b1:	ff 75 08             	pushl  0x8(%ebp)
801012b4:	e8 b7 ee ff ff       	call   80100170 <bread>
801012b9:	89 c3                	mov    %eax,%ebx
  memmove(sb, bp->data, sizeof(*sb));
801012bb:	8d 40 5c             	lea    0x5c(%eax),%eax
801012be:	83 c4 0c             	add    $0xc,%esp
801012c1:	6a 1c                	push   $0x1c
801012c3:	50                   	push   %eax
801012c4:	ff 75 0c             	pushl  0xc(%ebp)
801012c7:	e8 d5 2b 00 00       	call   80103ea1 <memmove>
  brelse(bp);
801012cc:	89 1c 24             	mov    %ebx,(%esp)
801012cf:	e8 0d ef ff ff       	call   801001e1 <brelse>
}
801012d4:	83 c4 10             	add    $0x10,%esp
801012d7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801012da:	c9                   	leave  
801012db:	c3                   	ret    

801012dc <bfree>:
{
801012dc:	55                   	push   %ebp
801012dd:	89 e5                	mov    %esp,%ebp
801012df:	57                   	push   %edi
801012e0:	56                   	push   %esi
801012e1:	53                   	push   %ebx
801012e2:	83 ec 14             	sub    $0x14,%esp
801012e5:	89 c3                	mov    %eax,%ebx
801012e7:	89 d6                	mov    %edx,%esi
  readsb(dev, &sb);
801012e9:	68 20 2a 11 80       	push   $0x80112a20
801012ee:	50                   	push   %eax
801012ef:	e8 b0 ff ff ff       	call   801012a4 <readsb>
  bp = bread(dev, BBLOCK(b, sb));
801012f4:	89 f0                	mov    %esi,%eax
801012f6:	c1 e8 0c             	shr    $0xc,%eax
801012f9:	83 c4 08             	add    $0x8,%esp
801012fc:	03 05 38 2a 11 80    	add    0x80112a38,%eax
80101302:	50                   	push   %eax
80101303:	53                   	push   %ebx
80101304:	e8 67 ee ff ff       	call   80100170 <bread>
80101309:	89 c3                	mov    %eax,%ebx
  bi = b % BPB;
8010130b:	89 f7                	mov    %esi,%edi
8010130d:	81 e7 ff 0f 00 00    	and    $0xfff,%edi
  m = 1 << (bi % 8);
80101313:	89 f1                	mov    %esi,%ecx
80101315:	83 e1 07             	and    $0x7,%ecx
80101318:	b8 01 00 00 00       	mov    $0x1,%eax
8010131d:	d3 e0                	shl    %cl,%eax
  if((bp->data[bi/8] & m) == 0)
8010131f:	83 c4 10             	add    $0x10,%esp
80101322:	c1 ff 03             	sar    $0x3,%edi
80101325:	0f b6 54 3b 5c       	movzbl 0x5c(%ebx,%edi,1),%edx
8010132a:	0f b6 ca             	movzbl %dl,%ecx
8010132d:	85 c1                	test   %eax,%ecx
8010132f:	74 24                	je     80101355 <bfree+0x79>
  bp->data[bi/8] &= ~m;
80101331:	f7 d0                	not    %eax
80101333:	21 d0                	and    %edx,%eax
80101335:	88 44 3b 5c          	mov    %al,0x5c(%ebx,%edi,1)
  log_write(bp);
80101339:	83 ec 0c             	sub    $0xc,%esp
8010133c:	53                   	push   %ebx
8010133d:	e8 7b 16 00 00       	call   801029bd <log_write>
  brelse(bp);
80101342:	89 1c 24             	mov    %ebx,(%esp)
80101345:	e8 97 ee ff ff       	call   801001e1 <brelse>
}
8010134a:	83 c4 10             	add    $0x10,%esp
8010134d:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101350:	5b                   	pop    %ebx
80101351:	5e                   	pop    %esi
80101352:	5f                   	pop    %edi
80101353:	5d                   	pop    %ebp
80101354:	c3                   	ret    
    panic("freeing free block");
80101355:	83 ec 0c             	sub    $0xc,%esp
80101358:	68 60 67 10 80       	push   $0x80106760
8010135d:	e8 fa ef ff ff       	call   8010035c <panic>

80101362 <iinit>:
{
80101362:	f3 0f 1e fb          	endbr32 
80101366:	55                   	push   %ebp
80101367:	89 e5                	mov    %esp,%ebp
80101369:	53                   	push   %ebx
8010136a:	83 ec 0c             	sub    $0xc,%esp
  initlock(&icache.lock, "icache");
8010136d:	68 73 67 10 80       	push   $0x80106773
80101372:	68 40 2a 11 80       	push   $0x80112a40
80101377:	e8 a1 28 00 00       	call   80103c1d <initlock>
  for(i = 0; i < NINODE; i++) {
8010137c:	83 c4 10             	add    $0x10,%esp
8010137f:	bb 00 00 00 00       	mov    $0x0,%ebx
80101384:	83 fb 31             	cmp    $0x31,%ebx
80101387:	7f 23                	jg     801013ac <iinit+0x4a>
    initsleeplock(&icache.inode[i].lock, "inode");
80101389:	83 ec 08             	sub    $0x8,%esp
8010138c:	68 7a 67 10 80       	push   $0x8010677a
80101391:	8d 14 db             	lea    (%ebx,%ebx,8),%edx
80101394:	89 d0                	mov    %edx,%eax
80101396:	c1 e0 04             	shl    $0x4,%eax
80101399:	05 80 2a 11 80       	add    $0x80112a80,%eax
8010139e:	50                   	push   %eax
8010139f:	e8 85 27 00 00       	call   80103b29 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
801013a4:	83 c3 01             	add    $0x1,%ebx
801013a7:	83 c4 10             	add    $0x10,%esp
801013aa:	eb d8                	jmp    80101384 <iinit+0x22>
  readsb(dev, &sb);
801013ac:	83 ec 08             	sub    $0x8,%esp
801013af:	68 20 2a 11 80       	push   $0x80112a20
801013b4:	ff 75 08             	pushl  0x8(%ebp)
801013b7:	e8 e8 fe ff ff       	call   801012a4 <readsb>
  cprintf("sb: size %d nblocks %d ninodes %d nlog %d logstart %d\
801013bc:	ff 35 38 2a 11 80    	pushl  0x80112a38
801013c2:	ff 35 34 2a 11 80    	pushl  0x80112a34
801013c8:	ff 35 30 2a 11 80    	pushl  0x80112a30
801013ce:	ff 35 2c 2a 11 80    	pushl  0x80112a2c
801013d4:	ff 35 28 2a 11 80    	pushl  0x80112a28
801013da:	ff 35 24 2a 11 80    	pushl  0x80112a24
801013e0:	ff 35 20 2a 11 80    	pushl  0x80112a20
801013e6:	68 e0 67 10 80       	push   $0x801067e0
801013eb:	e8 39 f2 ff ff       	call   80100629 <cprintf>
}
801013f0:	83 c4 30             	add    $0x30,%esp
801013f3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801013f6:	c9                   	leave  
801013f7:	c3                   	ret    

801013f8 <ialloc>:
{
801013f8:	f3 0f 1e fb          	endbr32 
801013fc:	55                   	push   %ebp
801013fd:	89 e5                	mov    %esp,%ebp
801013ff:	57                   	push   %edi
80101400:	56                   	push   %esi
80101401:	53                   	push   %ebx
80101402:	83 ec 1c             	sub    $0x1c,%esp
80101405:	8b 45 0c             	mov    0xc(%ebp),%eax
80101408:	89 45 e0             	mov    %eax,-0x20(%ebp)
  for(inum = 1; inum < sb.ninodes; inum++){
8010140b:	bb 01 00 00 00       	mov    $0x1,%ebx
80101410:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
80101413:	39 1d 28 2a 11 80    	cmp    %ebx,0x80112a28
80101419:	76 76                	jbe    80101491 <ialloc+0x99>
    bp = bread(dev, IBLOCK(inum, sb));
8010141b:	89 d8                	mov    %ebx,%eax
8010141d:	c1 e8 03             	shr    $0x3,%eax
80101420:	83 ec 08             	sub    $0x8,%esp
80101423:	03 05 34 2a 11 80    	add    0x80112a34,%eax
80101429:	50                   	push   %eax
8010142a:	ff 75 08             	pushl  0x8(%ebp)
8010142d:	e8 3e ed ff ff       	call   80100170 <bread>
80101432:	89 c6                	mov    %eax,%esi
    dip = (struct dinode*)bp->data + inum%IPB;
80101434:	89 d8                	mov    %ebx,%eax
80101436:	83 e0 07             	and    $0x7,%eax
80101439:	c1 e0 06             	shl    $0x6,%eax
8010143c:	8d 7c 06 5c          	lea    0x5c(%esi,%eax,1),%edi
    if(dip->type == 0){  // a free inode
80101440:	83 c4 10             	add    $0x10,%esp
80101443:	66 83 3f 00          	cmpw   $0x0,(%edi)
80101447:	74 11                	je     8010145a <ialloc+0x62>
    brelse(bp);
80101449:	83 ec 0c             	sub    $0xc,%esp
8010144c:	56                   	push   %esi
8010144d:	e8 8f ed ff ff       	call   801001e1 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
80101452:	83 c3 01             	add    $0x1,%ebx
80101455:	83 c4 10             	add    $0x10,%esp
80101458:	eb b6                	jmp    80101410 <ialloc+0x18>
      memset(dip, 0, sizeof(*dip));
8010145a:	83 ec 04             	sub    $0x4,%esp
8010145d:	6a 40                	push   $0x40
8010145f:	6a 00                	push   $0x0
80101461:	57                   	push   %edi
80101462:	e8 ba 29 00 00       	call   80103e21 <memset>
      dip->type = type;
80101467:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
8010146b:	66 89 07             	mov    %ax,(%edi)
      log_write(bp);   // mark it allocated on the disk
8010146e:	89 34 24             	mov    %esi,(%esp)
80101471:	e8 47 15 00 00       	call   801029bd <log_write>
      brelse(bp);
80101476:	89 34 24             	mov    %esi,(%esp)
80101479:	e8 63 ed ff ff       	call   801001e1 <brelse>
      return iget(dev, inum);
8010147e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80101481:	8b 45 08             	mov    0x8(%ebp),%eax
80101484:	e8 6c fd ff ff       	call   801011f5 <iget>
}
80101489:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010148c:	5b                   	pop    %ebx
8010148d:	5e                   	pop    %esi
8010148e:	5f                   	pop    %edi
8010148f:	5d                   	pop    %ebp
80101490:	c3                   	ret    
  panic("ialloc: no inodes");
80101491:	83 ec 0c             	sub    $0xc,%esp
80101494:	68 80 67 10 80       	push   $0x80106780
80101499:	e8 be ee ff ff       	call   8010035c <panic>

8010149e <iupdate>:
{
8010149e:	f3 0f 1e fb          	endbr32 
801014a2:	55                   	push   %ebp
801014a3:	89 e5                	mov    %esp,%ebp
801014a5:	56                   	push   %esi
801014a6:	53                   	push   %ebx
801014a7:	8b 5d 08             	mov    0x8(%ebp),%ebx
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
801014aa:	8b 43 04             	mov    0x4(%ebx),%eax
801014ad:	c1 e8 03             	shr    $0x3,%eax
801014b0:	83 ec 08             	sub    $0x8,%esp
801014b3:	03 05 34 2a 11 80    	add    0x80112a34,%eax
801014b9:	50                   	push   %eax
801014ba:	ff 33                	pushl  (%ebx)
801014bc:	e8 af ec ff ff       	call   80100170 <bread>
801014c1:	89 c6                	mov    %eax,%esi
  dip = (struct dinode*)bp->data + ip->inum%IPB;
801014c3:	8b 43 04             	mov    0x4(%ebx),%eax
801014c6:	83 e0 07             	and    $0x7,%eax
801014c9:	c1 e0 06             	shl    $0x6,%eax
801014cc:	8d 44 06 5c          	lea    0x5c(%esi,%eax,1),%eax
  dip->type = ip->type;
801014d0:	0f b7 53 50          	movzwl 0x50(%ebx),%edx
801014d4:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
801014d7:	0f b7 53 52          	movzwl 0x52(%ebx),%edx
801014db:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
801014df:	0f b7 53 54          	movzwl 0x54(%ebx),%edx
801014e3:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
801014e7:	0f b7 53 56          	movzwl 0x56(%ebx),%edx
801014eb:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
801014ef:	8b 53 58             	mov    0x58(%ebx),%edx
801014f2:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
801014f5:	83 c3 5c             	add    $0x5c,%ebx
801014f8:	83 c0 0c             	add    $0xc,%eax
801014fb:	83 c4 0c             	add    $0xc,%esp
801014fe:	6a 34                	push   $0x34
80101500:	53                   	push   %ebx
80101501:	50                   	push   %eax
80101502:	e8 9a 29 00 00       	call   80103ea1 <memmove>
  log_write(bp);
80101507:	89 34 24             	mov    %esi,(%esp)
8010150a:	e8 ae 14 00 00       	call   801029bd <log_write>
  brelse(bp);
8010150f:	89 34 24             	mov    %esi,(%esp)
80101512:	e8 ca ec ff ff       	call   801001e1 <brelse>
}
80101517:	83 c4 10             	add    $0x10,%esp
8010151a:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010151d:	5b                   	pop    %ebx
8010151e:	5e                   	pop    %esi
8010151f:	5d                   	pop    %ebp
80101520:	c3                   	ret    

80101521 <itrunc>:
{
80101521:	55                   	push   %ebp
80101522:	89 e5                	mov    %esp,%ebp
80101524:	57                   	push   %edi
80101525:	56                   	push   %esi
80101526:	53                   	push   %ebx
80101527:	83 ec 1c             	sub    $0x1c,%esp
8010152a:	89 c6                	mov    %eax,%esi
  for(i = 0; i < NDIRECT; i++){
8010152c:	bb 00 00 00 00       	mov    $0x0,%ebx
80101531:	eb 03                	jmp    80101536 <itrunc+0x15>
80101533:	83 c3 01             	add    $0x1,%ebx
80101536:	83 fb 0b             	cmp    $0xb,%ebx
80101539:	7f 19                	jg     80101554 <itrunc+0x33>
    if(ip->addrs[i]){
8010153b:	8b 54 9e 5c          	mov    0x5c(%esi,%ebx,4),%edx
8010153f:	85 d2                	test   %edx,%edx
80101541:	74 f0                	je     80101533 <itrunc+0x12>
      bfree(ip->dev, ip->addrs[i]);
80101543:	8b 06                	mov    (%esi),%eax
80101545:	e8 92 fd ff ff       	call   801012dc <bfree>
      ip->addrs[i] = 0;
8010154a:	c7 44 9e 5c 00 00 00 	movl   $0x0,0x5c(%esi,%ebx,4)
80101551:	00 
80101552:	eb df                	jmp    80101533 <itrunc+0x12>
  if(ip->addrs[NDIRECT]){
80101554:	8b 86 8c 00 00 00    	mov    0x8c(%esi),%eax
8010155a:	85 c0                	test   %eax,%eax
8010155c:	75 1b                	jne    80101579 <itrunc+0x58>
  ip->size = 0;
8010155e:	c7 46 58 00 00 00 00 	movl   $0x0,0x58(%esi)
  iupdate(ip);
80101565:	83 ec 0c             	sub    $0xc,%esp
80101568:	56                   	push   %esi
80101569:	e8 30 ff ff ff       	call   8010149e <iupdate>
}
8010156e:	83 c4 10             	add    $0x10,%esp
80101571:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101574:	5b                   	pop    %ebx
80101575:	5e                   	pop    %esi
80101576:	5f                   	pop    %edi
80101577:	5d                   	pop    %ebp
80101578:	c3                   	ret    
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
80101579:	83 ec 08             	sub    $0x8,%esp
8010157c:	50                   	push   %eax
8010157d:	ff 36                	pushl  (%esi)
8010157f:	e8 ec eb ff ff       	call   80100170 <bread>
80101584:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    a = (uint*)bp->data;
80101587:	8d 78 5c             	lea    0x5c(%eax),%edi
    for(j = 0; j < NINDIRECT; j++){
8010158a:	83 c4 10             	add    $0x10,%esp
8010158d:	bb 00 00 00 00       	mov    $0x0,%ebx
80101592:	eb 0a                	jmp    8010159e <itrunc+0x7d>
        bfree(ip->dev, a[j]);
80101594:	8b 06                	mov    (%esi),%eax
80101596:	e8 41 fd ff ff       	call   801012dc <bfree>
    for(j = 0; j < NINDIRECT; j++){
8010159b:	83 c3 01             	add    $0x1,%ebx
8010159e:	83 fb 7f             	cmp    $0x7f,%ebx
801015a1:	77 09                	ja     801015ac <itrunc+0x8b>
      if(a[j])
801015a3:	8b 14 9f             	mov    (%edi,%ebx,4),%edx
801015a6:	85 d2                	test   %edx,%edx
801015a8:	74 f1                	je     8010159b <itrunc+0x7a>
801015aa:	eb e8                	jmp    80101594 <itrunc+0x73>
    brelse(bp);
801015ac:	83 ec 0c             	sub    $0xc,%esp
801015af:	ff 75 e4             	pushl  -0x1c(%ebp)
801015b2:	e8 2a ec ff ff       	call   801001e1 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
801015b7:	8b 06                	mov    (%esi),%eax
801015b9:	8b 96 8c 00 00 00    	mov    0x8c(%esi),%edx
801015bf:	e8 18 fd ff ff       	call   801012dc <bfree>
    ip->addrs[NDIRECT] = 0;
801015c4:	c7 86 8c 00 00 00 00 	movl   $0x0,0x8c(%esi)
801015cb:	00 00 00 
801015ce:	83 c4 10             	add    $0x10,%esp
801015d1:	eb 8b                	jmp    8010155e <itrunc+0x3d>

801015d3 <idup>:
{
801015d3:	f3 0f 1e fb          	endbr32 
801015d7:	55                   	push   %ebp
801015d8:	89 e5                	mov    %esp,%ebp
801015da:	53                   	push   %ebx
801015db:	83 ec 10             	sub    $0x10,%esp
801015de:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&icache.lock);
801015e1:	68 40 2a 11 80       	push   $0x80112a40
801015e6:	e8 82 27 00 00       	call   80103d6d <acquire>
  ip->ref++;
801015eb:	8b 43 08             	mov    0x8(%ebx),%eax
801015ee:	83 c0 01             	add    $0x1,%eax
801015f1:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
801015f4:	c7 04 24 40 2a 11 80 	movl   $0x80112a40,(%esp)
801015fb:	e8 d6 27 00 00       	call   80103dd6 <release>
}
80101600:	89 d8                	mov    %ebx,%eax
80101602:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101605:	c9                   	leave  
80101606:	c3                   	ret    

80101607 <ilock>:
{
80101607:	f3 0f 1e fb          	endbr32 
8010160b:	55                   	push   %ebp
8010160c:	89 e5                	mov    %esp,%ebp
8010160e:	56                   	push   %esi
8010160f:	53                   	push   %ebx
80101610:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(ip == 0 || ip->ref < 1)
80101613:	85 db                	test   %ebx,%ebx
80101615:	74 22                	je     80101639 <ilock+0x32>
80101617:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
8010161b:	7e 1c                	jle    80101639 <ilock+0x32>
  acquiresleep(&ip->lock);
8010161d:	83 ec 0c             	sub    $0xc,%esp
80101620:	8d 43 0c             	lea    0xc(%ebx),%eax
80101623:	50                   	push   %eax
80101624:	e8 37 25 00 00       	call   80103b60 <acquiresleep>
  if(ip->valid == 0){
80101629:	83 c4 10             	add    $0x10,%esp
8010162c:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
80101630:	74 14                	je     80101646 <ilock+0x3f>
}
80101632:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101635:	5b                   	pop    %ebx
80101636:	5e                   	pop    %esi
80101637:	5d                   	pop    %ebp
80101638:	c3                   	ret    
    panic("ilock");
80101639:	83 ec 0c             	sub    $0xc,%esp
8010163c:	68 92 67 10 80       	push   $0x80106792
80101641:	e8 16 ed ff ff       	call   8010035c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
80101646:	8b 43 04             	mov    0x4(%ebx),%eax
80101649:	c1 e8 03             	shr    $0x3,%eax
8010164c:	83 ec 08             	sub    $0x8,%esp
8010164f:	03 05 34 2a 11 80    	add    0x80112a34,%eax
80101655:	50                   	push   %eax
80101656:	ff 33                	pushl  (%ebx)
80101658:	e8 13 eb ff ff       	call   80100170 <bread>
8010165d:	89 c6                	mov    %eax,%esi
    dip = (struct dinode*)bp->data + ip->inum%IPB;
8010165f:	8b 43 04             	mov    0x4(%ebx),%eax
80101662:	83 e0 07             	and    $0x7,%eax
80101665:	c1 e0 06             	shl    $0x6,%eax
80101668:	8d 44 06 5c          	lea    0x5c(%esi,%eax,1),%eax
    ip->type = dip->type;
8010166c:	0f b7 10             	movzwl (%eax),%edx
8010166f:	66 89 53 50          	mov    %dx,0x50(%ebx)
    ip->major = dip->major;
80101673:	0f b7 50 02          	movzwl 0x2(%eax),%edx
80101677:	66 89 53 52          	mov    %dx,0x52(%ebx)
    ip->minor = dip->minor;
8010167b:	0f b7 50 04          	movzwl 0x4(%eax),%edx
8010167f:	66 89 53 54          	mov    %dx,0x54(%ebx)
    ip->nlink = dip->nlink;
80101683:	0f b7 50 06          	movzwl 0x6(%eax),%edx
80101687:	66 89 53 56          	mov    %dx,0x56(%ebx)
    ip->size = dip->size;
8010168b:	8b 50 08             	mov    0x8(%eax),%edx
8010168e:	89 53 58             	mov    %edx,0x58(%ebx)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
80101691:	83 c0 0c             	add    $0xc,%eax
80101694:	8d 53 5c             	lea    0x5c(%ebx),%edx
80101697:	83 c4 0c             	add    $0xc,%esp
8010169a:	6a 34                	push   $0x34
8010169c:	50                   	push   %eax
8010169d:	52                   	push   %edx
8010169e:	e8 fe 27 00 00       	call   80103ea1 <memmove>
    brelse(bp);
801016a3:	89 34 24             	mov    %esi,(%esp)
801016a6:	e8 36 eb ff ff       	call   801001e1 <brelse>
    ip->valid = 1;
801016ab:	c7 43 4c 01 00 00 00 	movl   $0x1,0x4c(%ebx)
    if(ip->type == 0)
801016b2:	83 c4 10             	add    $0x10,%esp
801016b5:	66 83 7b 50 00       	cmpw   $0x0,0x50(%ebx)
801016ba:	0f 85 72 ff ff ff    	jne    80101632 <ilock+0x2b>
      panic("ilock: no type");
801016c0:	83 ec 0c             	sub    $0xc,%esp
801016c3:	68 98 67 10 80       	push   $0x80106798
801016c8:	e8 8f ec ff ff       	call   8010035c <panic>

801016cd <iunlock>:
{
801016cd:	f3 0f 1e fb          	endbr32 
801016d1:	55                   	push   %ebp
801016d2:	89 e5                	mov    %esp,%ebp
801016d4:	56                   	push   %esi
801016d5:	53                   	push   %ebx
801016d6:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
801016d9:	85 db                	test   %ebx,%ebx
801016db:	74 2c                	je     80101709 <iunlock+0x3c>
801016dd:	8d 73 0c             	lea    0xc(%ebx),%esi
801016e0:	83 ec 0c             	sub    $0xc,%esp
801016e3:	56                   	push   %esi
801016e4:	e8 09 25 00 00       	call   80103bf2 <holdingsleep>
801016e9:	83 c4 10             	add    $0x10,%esp
801016ec:	85 c0                	test   %eax,%eax
801016ee:	74 19                	je     80101709 <iunlock+0x3c>
801016f0:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
801016f4:	7e 13                	jle    80101709 <iunlock+0x3c>
  releasesleep(&ip->lock);
801016f6:	83 ec 0c             	sub    $0xc,%esp
801016f9:	56                   	push   %esi
801016fa:	e8 b4 24 00 00       	call   80103bb3 <releasesleep>
}
801016ff:	83 c4 10             	add    $0x10,%esp
80101702:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101705:	5b                   	pop    %ebx
80101706:	5e                   	pop    %esi
80101707:	5d                   	pop    %ebp
80101708:	c3                   	ret    
    panic("iunlock");
80101709:	83 ec 0c             	sub    $0xc,%esp
8010170c:	68 a7 67 10 80       	push   $0x801067a7
80101711:	e8 46 ec ff ff       	call   8010035c <panic>

80101716 <iput>:
{
80101716:	f3 0f 1e fb          	endbr32 
8010171a:	55                   	push   %ebp
8010171b:	89 e5                	mov    %esp,%ebp
8010171d:	57                   	push   %edi
8010171e:	56                   	push   %esi
8010171f:	53                   	push   %ebx
80101720:	83 ec 18             	sub    $0x18,%esp
80101723:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquiresleep(&ip->lock);
80101726:	8d 73 0c             	lea    0xc(%ebx),%esi
80101729:	56                   	push   %esi
8010172a:	e8 31 24 00 00       	call   80103b60 <acquiresleep>
  if(ip->valid && ip->nlink == 0){
8010172f:	83 c4 10             	add    $0x10,%esp
80101732:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
80101736:	74 07                	je     8010173f <iput+0x29>
80101738:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
8010173d:	74 35                	je     80101774 <iput+0x5e>
  releasesleep(&ip->lock);
8010173f:	83 ec 0c             	sub    $0xc,%esp
80101742:	56                   	push   %esi
80101743:	e8 6b 24 00 00       	call   80103bb3 <releasesleep>
  acquire(&icache.lock);
80101748:	c7 04 24 40 2a 11 80 	movl   $0x80112a40,(%esp)
8010174f:	e8 19 26 00 00       	call   80103d6d <acquire>
  ip->ref--;
80101754:	8b 43 08             	mov    0x8(%ebx),%eax
80101757:	83 e8 01             	sub    $0x1,%eax
8010175a:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
8010175d:	c7 04 24 40 2a 11 80 	movl   $0x80112a40,(%esp)
80101764:	e8 6d 26 00 00       	call   80103dd6 <release>
}
80101769:	83 c4 10             	add    $0x10,%esp
8010176c:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010176f:	5b                   	pop    %ebx
80101770:	5e                   	pop    %esi
80101771:	5f                   	pop    %edi
80101772:	5d                   	pop    %ebp
80101773:	c3                   	ret    
    acquire(&icache.lock);
80101774:	83 ec 0c             	sub    $0xc,%esp
80101777:	68 40 2a 11 80       	push   $0x80112a40
8010177c:	e8 ec 25 00 00       	call   80103d6d <acquire>
    int r = ip->ref;
80101781:	8b 7b 08             	mov    0x8(%ebx),%edi
    release(&icache.lock);
80101784:	c7 04 24 40 2a 11 80 	movl   $0x80112a40,(%esp)
8010178b:	e8 46 26 00 00       	call   80103dd6 <release>
    if(r == 1){
80101790:	83 c4 10             	add    $0x10,%esp
80101793:	83 ff 01             	cmp    $0x1,%edi
80101796:	75 a7                	jne    8010173f <iput+0x29>
      itrunc(ip);
80101798:	89 d8                	mov    %ebx,%eax
8010179a:	e8 82 fd ff ff       	call   80101521 <itrunc>
      ip->type = 0;
8010179f:	66 c7 43 50 00 00    	movw   $0x0,0x50(%ebx)
      iupdate(ip);
801017a5:	83 ec 0c             	sub    $0xc,%esp
801017a8:	53                   	push   %ebx
801017a9:	e8 f0 fc ff ff       	call   8010149e <iupdate>
      ip->valid = 0;
801017ae:	c7 43 4c 00 00 00 00 	movl   $0x0,0x4c(%ebx)
801017b5:	83 c4 10             	add    $0x10,%esp
801017b8:	eb 85                	jmp    8010173f <iput+0x29>

801017ba <iunlockput>:
{
801017ba:	f3 0f 1e fb          	endbr32 
801017be:	55                   	push   %ebp
801017bf:	89 e5                	mov    %esp,%ebp
801017c1:	53                   	push   %ebx
801017c2:	83 ec 10             	sub    $0x10,%esp
801017c5:	8b 5d 08             	mov    0x8(%ebp),%ebx
  iunlock(ip);
801017c8:	53                   	push   %ebx
801017c9:	e8 ff fe ff ff       	call   801016cd <iunlock>
  iput(ip);
801017ce:	89 1c 24             	mov    %ebx,(%esp)
801017d1:	e8 40 ff ff ff       	call   80101716 <iput>
}
801017d6:	83 c4 10             	add    $0x10,%esp
801017d9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801017dc:	c9                   	leave  
801017dd:	c3                   	ret    

801017de <stati>:
{
801017de:	f3 0f 1e fb          	endbr32 
801017e2:	55                   	push   %ebp
801017e3:	89 e5                	mov    %esp,%ebp
801017e5:	8b 55 08             	mov    0x8(%ebp),%edx
801017e8:	8b 45 0c             	mov    0xc(%ebp),%eax
  st->dev = ip->dev;
801017eb:	8b 0a                	mov    (%edx),%ecx
801017ed:	89 48 04             	mov    %ecx,0x4(%eax)
  st->ino = ip->inum;
801017f0:	8b 4a 04             	mov    0x4(%edx),%ecx
801017f3:	89 48 08             	mov    %ecx,0x8(%eax)
  st->type = ip->type;
801017f6:	0f b7 4a 50          	movzwl 0x50(%edx),%ecx
801017fa:	66 89 08             	mov    %cx,(%eax)
  st->nlink = ip->nlink;
801017fd:	0f b7 4a 56          	movzwl 0x56(%edx),%ecx
80101801:	66 89 48 0c          	mov    %cx,0xc(%eax)
  st->size = ip->size;
80101805:	8b 52 58             	mov    0x58(%edx),%edx
80101808:	89 50 10             	mov    %edx,0x10(%eax)
}
8010180b:	5d                   	pop    %ebp
8010180c:	c3                   	ret    

8010180d <readi>:
{
8010180d:	f3 0f 1e fb          	endbr32 
80101811:	55                   	push   %ebp
80101812:	89 e5                	mov    %esp,%ebp
80101814:	57                   	push   %edi
80101815:	56                   	push   %esi
80101816:	53                   	push   %ebx
80101817:	83 ec 1c             	sub    $0x1c,%esp
8010181a:	8b 75 10             	mov    0x10(%ebp),%esi
  if(ip->type == T_DEV){
8010181d:	8b 45 08             	mov    0x8(%ebp),%eax
80101820:	66 83 78 50 03       	cmpw   $0x3,0x50(%eax)
80101825:	74 2c                	je     80101853 <readi+0x46>
  if(off > ip->size || off + n < off)
80101827:	8b 45 08             	mov    0x8(%ebp),%eax
8010182a:	8b 40 58             	mov    0x58(%eax),%eax
8010182d:	39 f0                	cmp    %esi,%eax
8010182f:	0f 82 cb 00 00 00    	jb     80101900 <readi+0xf3>
80101835:	89 f2                	mov    %esi,%edx
80101837:	03 55 14             	add    0x14(%ebp),%edx
8010183a:	0f 82 c7 00 00 00    	jb     80101907 <readi+0xfa>
  if(off + n > ip->size)
80101840:	39 d0                	cmp    %edx,%eax
80101842:	73 05                	jae    80101849 <readi+0x3c>
    n = ip->size - off;
80101844:	29 f0                	sub    %esi,%eax
80101846:	89 45 14             	mov    %eax,0x14(%ebp)
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101849:	bf 00 00 00 00       	mov    $0x0,%edi
8010184e:	e9 8f 00 00 00       	jmp    801018e2 <readi+0xd5>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
80101853:	0f b7 40 52          	movzwl 0x52(%eax),%eax
80101857:	66 83 f8 09          	cmp    $0x9,%ax
8010185b:	0f 87 91 00 00 00    	ja     801018f2 <readi+0xe5>
80101861:	98                   	cwtl   
80101862:	8b 04 c5 c0 29 11 80 	mov    -0x7feed640(,%eax,8),%eax
80101869:	85 c0                	test   %eax,%eax
8010186b:	0f 84 88 00 00 00    	je     801018f9 <readi+0xec>
    return devsw[ip->major].read(ip, dst, n);
80101871:	83 ec 04             	sub    $0x4,%esp
80101874:	ff 75 14             	pushl  0x14(%ebp)
80101877:	ff 75 0c             	pushl  0xc(%ebp)
8010187a:	ff 75 08             	pushl  0x8(%ebp)
8010187d:	ff d0                	call   *%eax
8010187f:	83 c4 10             	add    $0x10,%esp
80101882:	eb 66                	jmp    801018ea <readi+0xdd>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80101884:	89 f2                	mov    %esi,%edx
80101886:	c1 ea 09             	shr    $0x9,%edx
80101889:	8b 45 08             	mov    0x8(%ebp),%eax
8010188c:	e8 be f8 ff ff       	call   8010114f <bmap>
80101891:	83 ec 08             	sub    $0x8,%esp
80101894:	50                   	push   %eax
80101895:	8b 45 08             	mov    0x8(%ebp),%eax
80101898:	ff 30                	pushl  (%eax)
8010189a:	e8 d1 e8 ff ff       	call   80100170 <bread>
8010189f:	89 c1                	mov    %eax,%ecx
    m = min(n - tot, BSIZE - off%BSIZE);
801018a1:	89 f0                	mov    %esi,%eax
801018a3:	25 ff 01 00 00       	and    $0x1ff,%eax
801018a8:	bb 00 02 00 00       	mov    $0x200,%ebx
801018ad:	29 c3                	sub    %eax,%ebx
801018af:	8b 55 14             	mov    0x14(%ebp),%edx
801018b2:	29 fa                	sub    %edi,%edx
801018b4:	83 c4 0c             	add    $0xc,%esp
801018b7:	39 d3                	cmp    %edx,%ebx
801018b9:	0f 47 da             	cmova  %edx,%ebx
    memmove(dst, bp->data + off%BSIZE, m);
801018bc:	53                   	push   %ebx
801018bd:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
801018c0:	8d 44 01 5c          	lea    0x5c(%ecx,%eax,1),%eax
801018c4:	50                   	push   %eax
801018c5:	ff 75 0c             	pushl  0xc(%ebp)
801018c8:	e8 d4 25 00 00       	call   80103ea1 <memmove>
    brelse(bp);
801018cd:	83 c4 04             	add    $0x4,%esp
801018d0:	ff 75 e4             	pushl  -0x1c(%ebp)
801018d3:	e8 09 e9 ff ff       	call   801001e1 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
801018d8:	01 df                	add    %ebx,%edi
801018da:	01 de                	add    %ebx,%esi
801018dc:	01 5d 0c             	add    %ebx,0xc(%ebp)
801018df:	83 c4 10             	add    $0x10,%esp
801018e2:	39 7d 14             	cmp    %edi,0x14(%ebp)
801018e5:	77 9d                	ja     80101884 <readi+0x77>
  return n;
801018e7:	8b 45 14             	mov    0x14(%ebp),%eax
}
801018ea:	8d 65 f4             	lea    -0xc(%ebp),%esp
801018ed:	5b                   	pop    %ebx
801018ee:	5e                   	pop    %esi
801018ef:	5f                   	pop    %edi
801018f0:	5d                   	pop    %ebp
801018f1:	c3                   	ret    
      return -1;
801018f2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801018f7:	eb f1                	jmp    801018ea <readi+0xdd>
801018f9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801018fe:	eb ea                	jmp    801018ea <readi+0xdd>
    return -1;
80101900:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101905:	eb e3                	jmp    801018ea <readi+0xdd>
80101907:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010190c:	eb dc                	jmp    801018ea <readi+0xdd>

8010190e <writei>:
{
8010190e:	f3 0f 1e fb          	endbr32 
80101912:	55                   	push   %ebp
80101913:	89 e5                	mov    %esp,%ebp
80101915:	57                   	push   %edi
80101916:	56                   	push   %esi
80101917:	53                   	push   %ebx
80101918:	83 ec 1c             	sub    $0x1c,%esp
8010191b:	8b 75 10             	mov    0x10(%ebp),%esi
  if(ip->type == T_DEV){
8010191e:	8b 45 08             	mov    0x8(%ebp),%eax
80101921:	66 83 78 50 03       	cmpw   $0x3,0x50(%eax)
80101926:	0f 84 9b 00 00 00    	je     801019c7 <writei+0xb9>
  if(off > ip->size || off + n < off)
8010192c:	8b 45 08             	mov    0x8(%ebp),%eax
8010192f:	39 70 58             	cmp    %esi,0x58(%eax)
80101932:	0f 82 f0 00 00 00    	jb     80101a28 <writei+0x11a>
80101938:	89 f0                	mov    %esi,%eax
8010193a:	03 45 14             	add    0x14(%ebp),%eax
8010193d:	0f 82 ec 00 00 00    	jb     80101a2f <writei+0x121>
  if(off + n > MAXFILE*BSIZE)
80101943:	3d 00 18 01 00       	cmp    $0x11800,%eax
80101948:	0f 87 e8 00 00 00    	ja     80101a36 <writei+0x128>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
8010194e:	bf 00 00 00 00       	mov    $0x0,%edi
80101953:	3b 7d 14             	cmp    0x14(%ebp),%edi
80101956:	0f 83 94 00 00 00    	jae    801019f0 <writei+0xe2>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
8010195c:	89 f2                	mov    %esi,%edx
8010195e:	c1 ea 09             	shr    $0x9,%edx
80101961:	8b 45 08             	mov    0x8(%ebp),%eax
80101964:	e8 e6 f7 ff ff       	call   8010114f <bmap>
80101969:	83 ec 08             	sub    $0x8,%esp
8010196c:	50                   	push   %eax
8010196d:	8b 45 08             	mov    0x8(%ebp),%eax
80101970:	ff 30                	pushl  (%eax)
80101972:	e8 f9 e7 ff ff       	call   80100170 <bread>
80101977:	89 c1                	mov    %eax,%ecx
    m = min(n - tot, BSIZE - off%BSIZE);
80101979:	89 f0                	mov    %esi,%eax
8010197b:	25 ff 01 00 00       	and    $0x1ff,%eax
80101980:	bb 00 02 00 00       	mov    $0x200,%ebx
80101985:	29 c3                	sub    %eax,%ebx
80101987:	8b 55 14             	mov    0x14(%ebp),%edx
8010198a:	29 fa                	sub    %edi,%edx
8010198c:	83 c4 0c             	add    $0xc,%esp
8010198f:	39 d3                	cmp    %edx,%ebx
80101991:	0f 47 da             	cmova  %edx,%ebx
    memmove(bp->data + off%BSIZE, src, m);
80101994:	53                   	push   %ebx
80101995:	ff 75 0c             	pushl  0xc(%ebp)
80101998:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
8010199b:	8d 44 01 5c          	lea    0x5c(%ecx,%eax,1),%eax
8010199f:	50                   	push   %eax
801019a0:	e8 fc 24 00 00       	call   80103ea1 <memmove>
    log_write(bp);
801019a5:	83 c4 04             	add    $0x4,%esp
801019a8:	ff 75 e4             	pushl  -0x1c(%ebp)
801019ab:	e8 0d 10 00 00       	call   801029bd <log_write>
    brelse(bp);
801019b0:	83 c4 04             	add    $0x4,%esp
801019b3:	ff 75 e4             	pushl  -0x1c(%ebp)
801019b6:	e8 26 e8 ff ff       	call   801001e1 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
801019bb:	01 df                	add    %ebx,%edi
801019bd:	01 de                	add    %ebx,%esi
801019bf:	01 5d 0c             	add    %ebx,0xc(%ebp)
801019c2:	83 c4 10             	add    $0x10,%esp
801019c5:	eb 8c                	jmp    80101953 <writei+0x45>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
801019c7:	0f b7 40 52          	movzwl 0x52(%eax),%eax
801019cb:	66 83 f8 09          	cmp    $0x9,%ax
801019cf:	77 49                	ja     80101a1a <writei+0x10c>
801019d1:	98                   	cwtl   
801019d2:	8b 04 c5 c4 29 11 80 	mov    -0x7feed63c(,%eax,8),%eax
801019d9:	85 c0                	test   %eax,%eax
801019db:	74 44                	je     80101a21 <writei+0x113>
    return devsw[ip->major].write(ip, src, n);
801019dd:	83 ec 04             	sub    $0x4,%esp
801019e0:	ff 75 14             	pushl  0x14(%ebp)
801019e3:	ff 75 0c             	pushl  0xc(%ebp)
801019e6:	ff 75 08             	pushl  0x8(%ebp)
801019e9:	ff d0                	call   *%eax
801019eb:	83 c4 10             	add    $0x10,%esp
801019ee:	eb 11                	jmp    80101a01 <writei+0xf3>
  if(n > 0 && off > ip->size){
801019f0:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
801019f4:	74 08                	je     801019fe <writei+0xf0>
801019f6:	8b 45 08             	mov    0x8(%ebp),%eax
801019f9:	39 70 58             	cmp    %esi,0x58(%eax)
801019fc:	72 0b                	jb     80101a09 <writei+0xfb>
  return n;
801019fe:	8b 45 14             	mov    0x14(%ebp),%eax
}
80101a01:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101a04:	5b                   	pop    %ebx
80101a05:	5e                   	pop    %esi
80101a06:	5f                   	pop    %edi
80101a07:	5d                   	pop    %ebp
80101a08:	c3                   	ret    
    ip->size = off;
80101a09:	89 70 58             	mov    %esi,0x58(%eax)
    iupdate(ip);
80101a0c:	83 ec 0c             	sub    $0xc,%esp
80101a0f:	50                   	push   %eax
80101a10:	e8 89 fa ff ff       	call   8010149e <iupdate>
80101a15:	83 c4 10             	add    $0x10,%esp
80101a18:	eb e4                	jmp    801019fe <writei+0xf0>
      return -1;
80101a1a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101a1f:	eb e0                	jmp    80101a01 <writei+0xf3>
80101a21:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101a26:	eb d9                	jmp    80101a01 <writei+0xf3>
    return -1;
80101a28:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101a2d:	eb d2                	jmp    80101a01 <writei+0xf3>
80101a2f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101a34:	eb cb                	jmp    80101a01 <writei+0xf3>
    return -1;
80101a36:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101a3b:	eb c4                	jmp    80101a01 <writei+0xf3>

80101a3d <namecmp>:
{
80101a3d:	f3 0f 1e fb          	endbr32 
80101a41:	55                   	push   %ebp
80101a42:	89 e5                	mov    %esp,%ebp
80101a44:	83 ec 0c             	sub    $0xc,%esp
  return strncmp(s, t, DIRSIZ);
80101a47:	6a 0e                	push   $0xe
80101a49:	ff 75 0c             	pushl  0xc(%ebp)
80101a4c:	ff 75 08             	pushl  0x8(%ebp)
80101a4f:	e8 bf 24 00 00       	call   80103f13 <strncmp>
}
80101a54:	c9                   	leave  
80101a55:	c3                   	ret    

80101a56 <dirlookup>:
{
80101a56:	f3 0f 1e fb          	endbr32 
80101a5a:	55                   	push   %ebp
80101a5b:	89 e5                	mov    %esp,%ebp
80101a5d:	57                   	push   %edi
80101a5e:	56                   	push   %esi
80101a5f:	53                   	push   %ebx
80101a60:	83 ec 1c             	sub    $0x1c,%esp
80101a63:	8b 75 08             	mov    0x8(%ebp),%esi
80101a66:	8b 7d 0c             	mov    0xc(%ebp),%edi
  if(dp->type != T_DIR)
80101a69:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
80101a6e:	75 07                	jne    80101a77 <dirlookup+0x21>
  for(off = 0; off < dp->size; off += sizeof(de)){
80101a70:	bb 00 00 00 00       	mov    $0x0,%ebx
80101a75:	eb 1d                	jmp    80101a94 <dirlookup+0x3e>
    panic("dirlookup not DIR");
80101a77:	83 ec 0c             	sub    $0xc,%esp
80101a7a:	68 af 67 10 80       	push   $0x801067af
80101a7f:	e8 d8 e8 ff ff       	call   8010035c <panic>
      panic("dirlookup read");
80101a84:	83 ec 0c             	sub    $0xc,%esp
80101a87:	68 c1 67 10 80       	push   $0x801067c1
80101a8c:	e8 cb e8 ff ff       	call   8010035c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
80101a91:	83 c3 10             	add    $0x10,%ebx
80101a94:	39 5e 58             	cmp    %ebx,0x58(%esi)
80101a97:	76 48                	jbe    80101ae1 <dirlookup+0x8b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80101a99:	6a 10                	push   $0x10
80101a9b:	53                   	push   %ebx
80101a9c:	8d 45 d8             	lea    -0x28(%ebp),%eax
80101a9f:	50                   	push   %eax
80101aa0:	56                   	push   %esi
80101aa1:	e8 67 fd ff ff       	call   8010180d <readi>
80101aa6:	83 c4 10             	add    $0x10,%esp
80101aa9:	83 f8 10             	cmp    $0x10,%eax
80101aac:	75 d6                	jne    80101a84 <dirlookup+0x2e>
    if(de.inum == 0)
80101aae:	66 83 7d d8 00       	cmpw   $0x0,-0x28(%ebp)
80101ab3:	74 dc                	je     80101a91 <dirlookup+0x3b>
    if(namecmp(name, de.name) == 0){
80101ab5:	83 ec 08             	sub    $0x8,%esp
80101ab8:	8d 45 da             	lea    -0x26(%ebp),%eax
80101abb:	50                   	push   %eax
80101abc:	57                   	push   %edi
80101abd:	e8 7b ff ff ff       	call   80101a3d <namecmp>
80101ac2:	83 c4 10             	add    $0x10,%esp
80101ac5:	85 c0                	test   %eax,%eax
80101ac7:	75 c8                	jne    80101a91 <dirlookup+0x3b>
      if(poff)
80101ac9:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80101acd:	74 05                	je     80101ad4 <dirlookup+0x7e>
        *poff = off;
80101acf:	8b 45 10             	mov    0x10(%ebp),%eax
80101ad2:	89 18                	mov    %ebx,(%eax)
      inum = de.inum;
80101ad4:	0f b7 55 d8          	movzwl -0x28(%ebp),%edx
      return iget(dp->dev, inum);
80101ad8:	8b 06                	mov    (%esi),%eax
80101ada:	e8 16 f7 ff ff       	call   801011f5 <iget>
80101adf:	eb 05                	jmp    80101ae6 <dirlookup+0x90>
  return 0;
80101ae1:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101ae6:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101ae9:	5b                   	pop    %ebx
80101aea:	5e                   	pop    %esi
80101aeb:	5f                   	pop    %edi
80101aec:	5d                   	pop    %ebp
80101aed:	c3                   	ret    

80101aee <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
80101aee:	55                   	push   %ebp
80101aef:	89 e5                	mov    %esp,%ebp
80101af1:	57                   	push   %edi
80101af2:	56                   	push   %esi
80101af3:	53                   	push   %ebx
80101af4:	83 ec 1c             	sub    $0x1c,%esp
80101af7:	89 c3                	mov    %eax,%ebx
80101af9:	89 55 e0             	mov    %edx,-0x20(%ebp)
80101afc:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
  struct inode *ip, *next;

  if(*path == '/')
80101aff:	80 38 2f             	cmpb   $0x2f,(%eax)
80101b02:	74 17                	je     80101b1b <namex+0x2d>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
80101b04:	e8 11 18 00 00       	call   8010331a <myproc>
80101b09:	83 ec 0c             	sub    $0xc,%esp
80101b0c:	ff 70 68             	pushl  0x68(%eax)
80101b0f:	e8 bf fa ff ff       	call   801015d3 <idup>
80101b14:	89 c6                	mov    %eax,%esi
80101b16:	83 c4 10             	add    $0x10,%esp
80101b19:	eb 53                	jmp    80101b6e <namex+0x80>
    ip = iget(ROOTDEV, ROOTINO);
80101b1b:	ba 01 00 00 00       	mov    $0x1,%edx
80101b20:	b8 01 00 00 00       	mov    $0x1,%eax
80101b25:	e8 cb f6 ff ff       	call   801011f5 <iget>
80101b2a:	89 c6                	mov    %eax,%esi
80101b2c:	eb 40                	jmp    80101b6e <namex+0x80>

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
      iunlockput(ip);
80101b2e:	83 ec 0c             	sub    $0xc,%esp
80101b31:	56                   	push   %esi
80101b32:	e8 83 fc ff ff       	call   801017ba <iunlockput>
      return 0;
80101b37:	83 c4 10             	add    $0x10,%esp
80101b3a:	be 00 00 00 00       	mov    $0x0,%esi
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
80101b3f:	89 f0                	mov    %esi,%eax
80101b41:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101b44:	5b                   	pop    %ebx
80101b45:	5e                   	pop    %esi
80101b46:	5f                   	pop    %edi
80101b47:	5d                   	pop    %ebp
80101b48:	c3                   	ret    
    if((next = dirlookup(ip, name, 0)) == 0){
80101b49:	83 ec 04             	sub    $0x4,%esp
80101b4c:	6a 00                	push   $0x0
80101b4e:	ff 75 e4             	pushl  -0x1c(%ebp)
80101b51:	56                   	push   %esi
80101b52:	e8 ff fe ff ff       	call   80101a56 <dirlookup>
80101b57:	89 c7                	mov    %eax,%edi
80101b59:	83 c4 10             	add    $0x10,%esp
80101b5c:	85 c0                	test   %eax,%eax
80101b5e:	74 4a                	je     80101baa <namex+0xbc>
    iunlockput(ip);
80101b60:	83 ec 0c             	sub    $0xc,%esp
80101b63:	56                   	push   %esi
80101b64:	e8 51 fc ff ff       	call   801017ba <iunlockput>
80101b69:	83 c4 10             	add    $0x10,%esp
    ip = next;
80101b6c:	89 fe                	mov    %edi,%esi
  while((path = skipelem(path, name)) != 0){
80101b6e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80101b71:	89 d8                	mov    %ebx,%eax
80101b73:	e8 3b f4 ff ff       	call   80100fb3 <skipelem>
80101b78:	89 c3                	mov    %eax,%ebx
80101b7a:	85 c0                	test   %eax,%eax
80101b7c:	74 3c                	je     80101bba <namex+0xcc>
    ilock(ip);
80101b7e:	83 ec 0c             	sub    $0xc,%esp
80101b81:	56                   	push   %esi
80101b82:	e8 80 fa ff ff       	call   80101607 <ilock>
    if(ip->type != T_DIR){
80101b87:	83 c4 10             	add    $0x10,%esp
80101b8a:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
80101b8f:	75 9d                	jne    80101b2e <namex+0x40>
    if(nameiparent && *path == '\0'){
80101b91:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80101b95:	74 b2                	je     80101b49 <namex+0x5b>
80101b97:	80 3b 00             	cmpb   $0x0,(%ebx)
80101b9a:	75 ad                	jne    80101b49 <namex+0x5b>
      iunlock(ip);
80101b9c:	83 ec 0c             	sub    $0xc,%esp
80101b9f:	56                   	push   %esi
80101ba0:	e8 28 fb ff ff       	call   801016cd <iunlock>
      return ip;
80101ba5:	83 c4 10             	add    $0x10,%esp
80101ba8:	eb 95                	jmp    80101b3f <namex+0x51>
      iunlockput(ip);
80101baa:	83 ec 0c             	sub    $0xc,%esp
80101bad:	56                   	push   %esi
80101bae:	e8 07 fc ff ff       	call   801017ba <iunlockput>
      return 0;
80101bb3:	83 c4 10             	add    $0x10,%esp
80101bb6:	89 fe                	mov    %edi,%esi
80101bb8:	eb 85                	jmp    80101b3f <namex+0x51>
  if(nameiparent){
80101bba:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80101bbe:	0f 84 7b ff ff ff    	je     80101b3f <namex+0x51>
    iput(ip);
80101bc4:	83 ec 0c             	sub    $0xc,%esp
80101bc7:	56                   	push   %esi
80101bc8:	e8 49 fb ff ff       	call   80101716 <iput>
    return 0;
80101bcd:	83 c4 10             	add    $0x10,%esp
80101bd0:	89 de                	mov    %ebx,%esi
80101bd2:	e9 68 ff ff ff       	jmp    80101b3f <namex+0x51>

80101bd7 <dirlink>:
{
80101bd7:	f3 0f 1e fb          	endbr32 
80101bdb:	55                   	push   %ebp
80101bdc:	89 e5                	mov    %esp,%ebp
80101bde:	57                   	push   %edi
80101bdf:	56                   	push   %esi
80101be0:	53                   	push   %ebx
80101be1:	83 ec 20             	sub    $0x20,%esp
80101be4:	8b 5d 08             	mov    0x8(%ebp),%ebx
80101be7:	8b 7d 0c             	mov    0xc(%ebp),%edi
  if((ip = dirlookup(dp, name, 0)) != 0){
80101bea:	6a 00                	push   $0x0
80101bec:	57                   	push   %edi
80101bed:	53                   	push   %ebx
80101bee:	e8 63 fe ff ff       	call   80101a56 <dirlookup>
80101bf3:	83 c4 10             	add    $0x10,%esp
80101bf6:	85 c0                	test   %eax,%eax
80101bf8:	75 07                	jne    80101c01 <dirlink+0x2a>
  for(off = 0; off < dp->size; off += sizeof(de)){
80101bfa:	b8 00 00 00 00       	mov    $0x0,%eax
80101bff:	eb 23                	jmp    80101c24 <dirlink+0x4d>
    iput(ip);
80101c01:	83 ec 0c             	sub    $0xc,%esp
80101c04:	50                   	push   %eax
80101c05:	e8 0c fb ff ff       	call   80101716 <iput>
    return -1;
80101c0a:	83 c4 10             	add    $0x10,%esp
80101c0d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101c12:	eb 63                	jmp    80101c77 <dirlink+0xa0>
      panic("dirlink read");
80101c14:	83 ec 0c             	sub    $0xc,%esp
80101c17:	68 d0 67 10 80       	push   $0x801067d0
80101c1c:	e8 3b e7 ff ff       	call   8010035c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
80101c21:	8d 46 10             	lea    0x10(%esi),%eax
80101c24:	89 c6                	mov    %eax,%esi
80101c26:	39 43 58             	cmp    %eax,0x58(%ebx)
80101c29:	76 1c                	jbe    80101c47 <dirlink+0x70>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80101c2b:	6a 10                	push   $0x10
80101c2d:	50                   	push   %eax
80101c2e:	8d 45 d8             	lea    -0x28(%ebp),%eax
80101c31:	50                   	push   %eax
80101c32:	53                   	push   %ebx
80101c33:	e8 d5 fb ff ff       	call   8010180d <readi>
80101c38:	83 c4 10             	add    $0x10,%esp
80101c3b:	83 f8 10             	cmp    $0x10,%eax
80101c3e:	75 d4                	jne    80101c14 <dirlink+0x3d>
    if(de.inum == 0)
80101c40:	66 83 7d d8 00       	cmpw   $0x0,-0x28(%ebp)
80101c45:	75 da                	jne    80101c21 <dirlink+0x4a>
  strncpy(de.name, name, DIRSIZ);
80101c47:	83 ec 04             	sub    $0x4,%esp
80101c4a:	6a 0e                	push   $0xe
80101c4c:	57                   	push   %edi
80101c4d:	8d 7d d8             	lea    -0x28(%ebp),%edi
80101c50:	8d 45 da             	lea    -0x26(%ebp),%eax
80101c53:	50                   	push   %eax
80101c54:	e8 fb 22 00 00       	call   80103f54 <strncpy>
  de.inum = inum;
80101c59:	8b 45 10             	mov    0x10(%ebp),%eax
80101c5c:	66 89 45 d8          	mov    %ax,-0x28(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80101c60:	6a 10                	push   $0x10
80101c62:	56                   	push   %esi
80101c63:	57                   	push   %edi
80101c64:	53                   	push   %ebx
80101c65:	e8 a4 fc ff ff       	call   8010190e <writei>
80101c6a:	83 c4 20             	add    $0x20,%esp
80101c6d:	83 f8 10             	cmp    $0x10,%eax
80101c70:	75 0d                	jne    80101c7f <dirlink+0xa8>
  return 0;
80101c72:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101c77:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101c7a:	5b                   	pop    %ebx
80101c7b:	5e                   	pop    %esi
80101c7c:	5f                   	pop    %edi
80101c7d:	5d                   	pop    %ebp
80101c7e:	c3                   	ret    
    panic("dirlink");
80101c7f:	83 ec 0c             	sub    $0xc,%esp
80101c82:	68 f8 6d 10 80       	push   $0x80106df8
80101c87:	e8 d0 e6 ff ff       	call   8010035c <panic>

80101c8c <namei>:

struct inode*
namei(char *path)
{
80101c8c:	f3 0f 1e fb          	endbr32 
80101c90:	55                   	push   %ebp
80101c91:	89 e5                	mov    %esp,%ebp
80101c93:	83 ec 18             	sub    $0x18,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
80101c96:	8d 4d ea             	lea    -0x16(%ebp),%ecx
80101c99:	ba 00 00 00 00       	mov    $0x0,%edx
80101c9e:	8b 45 08             	mov    0x8(%ebp),%eax
80101ca1:	e8 48 fe ff ff       	call   80101aee <namex>
}
80101ca6:	c9                   	leave  
80101ca7:	c3                   	ret    

80101ca8 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
80101ca8:	f3 0f 1e fb          	endbr32 
80101cac:	55                   	push   %ebp
80101cad:	89 e5                	mov    %esp,%ebp
80101caf:	83 ec 08             	sub    $0x8,%esp
  return namex(path, 1, name);
80101cb2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80101cb5:	ba 01 00 00 00       	mov    $0x1,%edx
80101cba:	8b 45 08             	mov    0x8(%ebp),%eax
80101cbd:	e8 2c fe ff ff       	call   80101aee <namex>
}
80101cc2:	c9                   	leave  
80101cc3:	c3                   	ret    

80101cc4 <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
80101cc4:	89 c1                	mov    %eax,%ecx
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80101cc6:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101ccb:	ec                   	in     (%dx),%al
80101ccc:	89 c2                	mov    %eax,%edx
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY)
80101cce:	83 e0 c0             	and    $0xffffffc0,%eax
80101cd1:	3c 40                	cmp    $0x40,%al
80101cd3:	75 f1                	jne    80101cc6 <idewait+0x2>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
80101cd5:	85 c9                	test   %ecx,%ecx
80101cd7:	74 0a                	je     80101ce3 <idewait+0x1f>
80101cd9:	f6 c2 21             	test   $0x21,%dl
80101cdc:	75 08                	jne    80101ce6 <idewait+0x22>
    return -1;
  return 0;
80101cde:	b9 00 00 00 00       	mov    $0x0,%ecx
}
80101ce3:	89 c8                	mov    %ecx,%eax
80101ce5:	c3                   	ret    
    return -1;
80101ce6:	b9 ff ff ff ff       	mov    $0xffffffff,%ecx
80101ceb:	eb f6                	jmp    80101ce3 <idewait+0x1f>

80101ced <idestart>:
}

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
80101ced:	55                   	push   %ebp
80101cee:	89 e5                	mov    %esp,%ebp
80101cf0:	56                   	push   %esi
80101cf1:	53                   	push   %ebx
  if(b == 0)
80101cf2:	85 c0                	test   %eax,%eax
80101cf4:	0f 84 91 00 00 00    	je     80101d8b <idestart+0x9e>
80101cfa:	89 c6                	mov    %eax,%esi
    panic("idestart");
  if(b->blockno >= FSSIZE)
80101cfc:	8b 58 08             	mov    0x8(%eax),%ebx
80101cff:	81 fb cf 07 00 00    	cmp    $0x7cf,%ebx
80101d05:	0f 87 8d 00 00 00    	ja     80101d98 <idestart+0xab>
  int read_cmd = (sector_per_block == 1) ? IDE_CMD_READ :  IDE_CMD_RDMUL;
  int write_cmd = (sector_per_block == 1) ? IDE_CMD_WRITE : IDE_CMD_WRMUL;

  if (sector_per_block > 7) panic("idestart");

  idewait(0);
80101d0b:	b8 00 00 00 00       	mov    $0x0,%eax
80101d10:	e8 af ff ff ff       	call   80101cc4 <idewait>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80101d15:	b8 00 00 00 00       	mov    $0x0,%eax
80101d1a:	ba f6 03 00 00       	mov    $0x3f6,%edx
80101d1f:	ee                   	out    %al,(%dx)
80101d20:	b8 01 00 00 00       	mov    $0x1,%eax
80101d25:	ba f2 01 00 00       	mov    $0x1f2,%edx
80101d2a:	ee                   	out    %al,(%dx)
80101d2b:	ba f3 01 00 00       	mov    $0x1f3,%edx
80101d30:	89 d8                	mov    %ebx,%eax
80101d32:	ee                   	out    %al,(%dx)
  outb(0x3f6, 0);  // generate interrupt
  outb(0x1f2, sector_per_block);  // number of sectors
  outb(0x1f3, sector & 0xff);
  outb(0x1f4, (sector >> 8) & 0xff);
80101d33:	89 d8                	mov    %ebx,%eax
80101d35:	c1 f8 08             	sar    $0x8,%eax
80101d38:	ba f4 01 00 00       	mov    $0x1f4,%edx
80101d3d:	ee                   	out    %al,(%dx)
  outb(0x1f5, (sector >> 16) & 0xff);
80101d3e:	89 d8                	mov    %ebx,%eax
80101d40:	c1 f8 10             	sar    $0x10,%eax
80101d43:	ba f5 01 00 00       	mov    $0x1f5,%edx
80101d48:	ee                   	out    %al,(%dx)
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((sector>>24)&0x0f));
80101d49:	0f b6 46 04          	movzbl 0x4(%esi),%eax
80101d4d:	c1 e0 04             	shl    $0x4,%eax
80101d50:	83 e0 10             	and    $0x10,%eax
80101d53:	c1 fb 18             	sar    $0x18,%ebx
80101d56:	83 e3 0f             	and    $0xf,%ebx
80101d59:	09 d8                	or     %ebx,%eax
80101d5b:	83 c8 e0             	or     $0xffffffe0,%eax
80101d5e:	ba f6 01 00 00       	mov    $0x1f6,%edx
80101d63:	ee                   	out    %al,(%dx)
  if(b->flags & B_DIRTY){
80101d64:	f6 06 04             	testb  $0x4,(%esi)
80101d67:	74 3c                	je     80101da5 <idestart+0xb8>
80101d69:	b8 30 00 00 00       	mov    $0x30,%eax
80101d6e:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101d73:	ee                   	out    %al,(%dx)
    outb(0x1f7, write_cmd);
    outsl(0x1f0, b->data, BSIZE/4);
80101d74:	83 c6 5c             	add    $0x5c,%esi
  asm volatile("cld; rep outsl" :
80101d77:	b9 80 00 00 00       	mov    $0x80,%ecx
80101d7c:	ba f0 01 00 00       	mov    $0x1f0,%edx
80101d81:	fc                   	cld    
80101d82:	f3 6f                	rep outsl %ds:(%esi),(%dx)
  } else {
    outb(0x1f7, read_cmd);
  }
}
80101d84:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101d87:	5b                   	pop    %ebx
80101d88:	5e                   	pop    %esi
80101d89:	5d                   	pop    %ebp
80101d8a:	c3                   	ret    
    panic("idestart");
80101d8b:	83 ec 0c             	sub    $0xc,%esp
80101d8e:	68 33 68 10 80       	push   $0x80106833
80101d93:	e8 c4 e5 ff ff       	call   8010035c <panic>
    panic("incorrect blockno");
80101d98:	83 ec 0c             	sub    $0xc,%esp
80101d9b:	68 3c 68 10 80       	push   $0x8010683c
80101da0:	e8 b7 e5 ff ff       	call   8010035c <panic>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80101da5:	b8 20 00 00 00       	mov    $0x20,%eax
80101daa:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101daf:	ee                   	out    %al,(%dx)
}
80101db0:	eb d2                	jmp    80101d84 <idestart+0x97>

80101db2 <ideinit>:
{
80101db2:	f3 0f 1e fb          	endbr32 
80101db6:	55                   	push   %ebp
80101db7:	89 e5                	mov    %esp,%ebp
80101db9:	83 ec 10             	sub    $0x10,%esp
  initlock(&idelock, "ide");
80101dbc:	68 4e 68 10 80       	push   $0x8010684e
80101dc1:	68 80 a5 10 80       	push   $0x8010a580
80101dc6:	e8 52 1e 00 00       	call   80103c1d <initlock>
  ioapicenable(IRQ_IDE, ncpu - 1);
80101dcb:	83 c4 08             	add    $0x8,%esp
80101dce:	a1 60 4d 11 80       	mov    0x80114d60,%eax
80101dd3:	83 e8 01             	sub    $0x1,%eax
80101dd6:	50                   	push   %eax
80101dd7:	6a 0e                	push   $0xe
80101dd9:	e8 5a 02 00 00       	call   80102038 <ioapicenable>
  idewait(0);
80101dde:	b8 00 00 00 00       	mov    $0x0,%eax
80101de3:	e8 dc fe ff ff       	call   80101cc4 <idewait>
80101de8:	b8 f0 ff ff ff       	mov    $0xfffffff0,%eax
80101ded:	ba f6 01 00 00       	mov    $0x1f6,%edx
80101df2:	ee                   	out    %al,(%dx)
  for(i=0; i<1000; i++){
80101df3:	83 c4 10             	add    $0x10,%esp
80101df6:	b9 00 00 00 00       	mov    $0x0,%ecx
80101dfb:	eb 03                	jmp    80101e00 <ideinit+0x4e>
80101dfd:	83 c1 01             	add    $0x1,%ecx
80101e00:	81 f9 e7 03 00 00    	cmp    $0x3e7,%ecx
80101e06:	7f 14                	jg     80101e1c <ideinit+0x6a>
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80101e08:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101e0d:	ec                   	in     (%dx),%al
    if(inb(0x1f7) != 0){
80101e0e:	84 c0                	test   %al,%al
80101e10:	74 eb                	je     80101dfd <ideinit+0x4b>
      havedisk1 = 1;
80101e12:	c7 05 60 a5 10 80 01 	movl   $0x1,0x8010a560
80101e19:	00 00 00 
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80101e1c:	b8 e0 ff ff ff       	mov    $0xffffffe0,%eax
80101e21:	ba f6 01 00 00       	mov    $0x1f6,%edx
80101e26:	ee                   	out    %al,(%dx)
}
80101e27:	c9                   	leave  
80101e28:	c3                   	ret    

80101e29 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
80101e29:	f3 0f 1e fb          	endbr32 
80101e2d:	55                   	push   %ebp
80101e2e:	89 e5                	mov    %esp,%ebp
80101e30:	57                   	push   %edi
80101e31:	53                   	push   %ebx
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
80101e32:	83 ec 0c             	sub    $0xc,%esp
80101e35:	68 80 a5 10 80       	push   $0x8010a580
80101e3a:	e8 2e 1f 00 00       	call   80103d6d <acquire>

  if((b = idequeue) == 0){
80101e3f:	8b 1d 64 a5 10 80    	mov    0x8010a564,%ebx
80101e45:	83 c4 10             	add    $0x10,%esp
80101e48:	85 db                	test   %ebx,%ebx
80101e4a:	74 48                	je     80101e94 <ideintr+0x6b>
    release(&idelock);
    return;
  }
  idequeue = b->qnext;
80101e4c:	8b 43 58             	mov    0x58(%ebx),%eax
80101e4f:	a3 64 a5 10 80       	mov    %eax,0x8010a564

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80101e54:	f6 03 04             	testb  $0x4,(%ebx)
80101e57:	74 4d                	je     80101ea6 <ideintr+0x7d>
    insl(0x1f0, b->data, BSIZE/4);

  // Wake process waiting for this buf.
  b->flags |= B_VALID;
80101e59:	8b 03                	mov    (%ebx),%eax
80101e5b:	83 c8 02             	or     $0x2,%eax
  b->flags &= ~B_DIRTY;
80101e5e:	83 e0 fb             	and    $0xfffffffb,%eax
80101e61:	89 03                	mov    %eax,(%ebx)
  wakeup(b);
80101e63:	83 ec 0c             	sub    $0xc,%esp
80101e66:	53                   	push   %ebx
80101e67:	e8 00 1b 00 00       	call   8010396c <wakeup>

  // Start disk on next buf in queue.
  if(idequeue != 0)
80101e6c:	a1 64 a5 10 80       	mov    0x8010a564,%eax
80101e71:	83 c4 10             	add    $0x10,%esp
80101e74:	85 c0                	test   %eax,%eax
80101e76:	74 05                	je     80101e7d <ideintr+0x54>
    idestart(idequeue);
80101e78:	e8 70 fe ff ff       	call   80101ced <idestart>

  release(&idelock);
80101e7d:	83 ec 0c             	sub    $0xc,%esp
80101e80:	68 80 a5 10 80       	push   $0x8010a580
80101e85:	e8 4c 1f 00 00       	call   80103dd6 <release>
80101e8a:	83 c4 10             	add    $0x10,%esp
}
80101e8d:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101e90:	5b                   	pop    %ebx
80101e91:	5f                   	pop    %edi
80101e92:	5d                   	pop    %ebp
80101e93:	c3                   	ret    
    release(&idelock);
80101e94:	83 ec 0c             	sub    $0xc,%esp
80101e97:	68 80 a5 10 80       	push   $0x8010a580
80101e9c:	e8 35 1f 00 00       	call   80103dd6 <release>
    return;
80101ea1:	83 c4 10             	add    $0x10,%esp
80101ea4:	eb e7                	jmp    80101e8d <ideintr+0x64>
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80101ea6:	b8 01 00 00 00       	mov    $0x1,%eax
80101eab:	e8 14 fe ff ff       	call   80101cc4 <idewait>
80101eb0:	85 c0                	test   %eax,%eax
80101eb2:	78 a5                	js     80101e59 <ideintr+0x30>
    insl(0x1f0, b->data, BSIZE/4);
80101eb4:	8d 7b 5c             	lea    0x5c(%ebx),%edi
  asm volatile("cld; rep insl" :
80101eb7:	b9 80 00 00 00       	mov    $0x80,%ecx
80101ebc:	ba f0 01 00 00       	mov    $0x1f0,%edx
80101ec1:	fc                   	cld    
80101ec2:	f3 6d                	rep insl (%dx),%es:(%edi)
}
80101ec4:	eb 93                	jmp    80101e59 <ideintr+0x30>

80101ec6 <iderw>:
// Sync buf with disk.
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
80101ec6:	f3 0f 1e fb          	endbr32 
80101eca:	55                   	push   %ebp
80101ecb:	89 e5                	mov    %esp,%ebp
80101ecd:	53                   	push   %ebx
80101ece:	83 ec 10             	sub    $0x10,%esp
80101ed1:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct buf **pp;

  if(!holdingsleep(&b->lock))
80101ed4:	8d 43 0c             	lea    0xc(%ebx),%eax
80101ed7:	50                   	push   %eax
80101ed8:	e8 15 1d 00 00       	call   80103bf2 <holdingsleep>
80101edd:	83 c4 10             	add    $0x10,%esp
80101ee0:	85 c0                	test   %eax,%eax
80101ee2:	74 37                	je     80101f1b <iderw+0x55>
    panic("iderw: buf not locked");
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
80101ee4:	8b 03                	mov    (%ebx),%eax
80101ee6:	83 e0 06             	and    $0x6,%eax
80101ee9:	83 f8 02             	cmp    $0x2,%eax
80101eec:	74 3a                	je     80101f28 <iderw+0x62>
    panic("iderw: nothing to do");
  if(b->dev != 0 && !havedisk1)
80101eee:	83 7b 04 00          	cmpl   $0x0,0x4(%ebx)
80101ef2:	74 09                	je     80101efd <iderw+0x37>
80101ef4:	83 3d 60 a5 10 80 00 	cmpl   $0x0,0x8010a560
80101efb:	74 38                	je     80101f35 <iderw+0x6f>
    panic("iderw: ide disk 1 not present");

  acquire(&idelock);  //DOC:acquire-lock
80101efd:	83 ec 0c             	sub    $0xc,%esp
80101f00:	68 80 a5 10 80       	push   $0x8010a580
80101f05:	e8 63 1e 00 00       	call   80103d6d <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80101f0a:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80101f11:	83 c4 10             	add    $0x10,%esp
80101f14:	ba 64 a5 10 80       	mov    $0x8010a564,%edx
80101f19:	eb 2a                	jmp    80101f45 <iderw+0x7f>
    panic("iderw: buf not locked");
80101f1b:	83 ec 0c             	sub    $0xc,%esp
80101f1e:	68 52 68 10 80       	push   $0x80106852
80101f23:	e8 34 e4 ff ff       	call   8010035c <panic>
    panic("iderw: nothing to do");
80101f28:	83 ec 0c             	sub    $0xc,%esp
80101f2b:	68 68 68 10 80       	push   $0x80106868
80101f30:	e8 27 e4 ff ff       	call   8010035c <panic>
    panic("iderw: ide disk 1 not present");
80101f35:	83 ec 0c             	sub    $0xc,%esp
80101f38:	68 7d 68 10 80       	push   $0x8010687d
80101f3d:	e8 1a e4 ff ff       	call   8010035c <panic>
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80101f42:	8d 50 58             	lea    0x58(%eax),%edx
80101f45:	8b 02                	mov    (%edx),%eax
80101f47:	85 c0                	test   %eax,%eax
80101f49:	75 f7                	jne    80101f42 <iderw+0x7c>
    ;
  *pp = b;
80101f4b:	89 1a                	mov    %ebx,(%edx)

  // Start disk if necessary.
  if(idequeue == b)
80101f4d:	39 1d 64 a5 10 80    	cmp    %ebx,0x8010a564
80101f53:	75 1a                	jne    80101f6f <iderw+0xa9>
    idestart(b);
80101f55:	89 d8                	mov    %ebx,%eax
80101f57:	e8 91 fd ff ff       	call   80101ced <idestart>
80101f5c:	eb 11                	jmp    80101f6f <iderw+0xa9>

  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
    sleep(b, &idelock);
80101f5e:	83 ec 08             	sub    $0x8,%esp
80101f61:	68 80 a5 10 80       	push   $0x8010a580
80101f66:	53                   	push   %ebx
80101f67:	e8 94 18 00 00       	call   80103800 <sleep>
80101f6c:	83 c4 10             	add    $0x10,%esp
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80101f6f:	8b 03                	mov    (%ebx),%eax
80101f71:	83 e0 06             	and    $0x6,%eax
80101f74:	83 f8 02             	cmp    $0x2,%eax
80101f77:	75 e5                	jne    80101f5e <iderw+0x98>
  }


  release(&idelock);
80101f79:	83 ec 0c             	sub    $0xc,%esp
80101f7c:	68 80 a5 10 80       	push   $0x8010a580
80101f81:	e8 50 1e 00 00       	call   80103dd6 <release>
}
80101f86:	83 c4 10             	add    $0x10,%esp
80101f89:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101f8c:	c9                   	leave  
80101f8d:	c3                   	ret    

80101f8e <ioapicread>:
};

static uint
ioapicread(int reg)
{
  ioapic->reg = reg;
80101f8e:	8b 15 94 46 11 80    	mov    0x80114694,%edx
80101f94:	89 02                	mov    %eax,(%edx)
  return ioapic->data;
80101f96:	a1 94 46 11 80       	mov    0x80114694,%eax
80101f9b:	8b 40 10             	mov    0x10(%eax),%eax
}
80101f9e:	c3                   	ret    

80101f9f <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
  ioapic->reg = reg;
80101f9f:	8b 0d 94 46 11 80    	mov    0x80114694,%ecx
80101fa5:	89 01                	mov    %eax,(%ecx)
  ioapic->data = data;
80101fa7:	a1 94 46 11 80       	mov    0x80114694,%eax
80101fac:	89 50 10             	mov    %edx,0x10(%eax)
}
80101faf:	c3                   	ret    

80101fb0 <ioapicinit>:

void
ioapicinit(void)
{
80101fb0:	f3 0f 1e fb          	endbr32 
80101fb4:	55                   	push   %ebp
80101fb5:	89 e5                	mov    %esp,%ebp
80101fb7:	57                   	push   %edi
80101fb8:	56                   	push   %esi
80101fb9:	53                   	push   %ebx
80101fba:	83 ec 0c             	sub    $0xc,%esp
  int i, id, maxintr;

  ioapic = (volatile struct ioapic*)IOAPIC;
80101fbd:	c7 05 94 46 11 80 00 	movl   $0xfec00000,0x80114694
80101fc4:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
80101fc7:	b8 01 00 00 00       	mov    $0x1,%eax
80101fcc:	e8 bd ff ff ff       	call   80101f8e <ioapicread>
80101fd1:	c1 e8 10             	shr    $0x10,%eax
80101fd4:	0f b6 f8             	movzbl %al,%edi
  id = ioapicread(REG_ID) >> 24;
80101fd7:	b8 00 00 00 00       	mov    $0x0,%eax
80101fdc:	e8 ad ff ff ff       	call   80101f8e <ioapicread>
80101fe1:	c1 e8 18             	shr    $0x18,%eax
  if(id != ioapicid)
80101fe4:	0f b6 15 c0 47 11 80 	movzbl 0x801147c0,%edx
80101feb:	39 c2                	cmp    %eax,%edx
80101fed:	75 2f                	jne    8010201e <ioapicinit+0x6e>
{
80101fef:	bb 00 00 00 00       	mov    $0x0,%ebx
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80101ff4:	39 fb                	cmp    %edi,%ebx
80101ff6:	7f 38                	jg     80102030 <ioapicinit+0x80>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
80101ff8:	8d 53 20             	lea    0x20(%ebx),%edx
80101ffb:	81 ca 00 00 01 00    	or     $0x10000,%edx
80102001:	8d 74 1b 10          	lea    0x10(%ebx,%ebx,1),%esi
80102005:	89 f0                	mov    %esi,%eax
80102007:	e8 93 ff ff ff       	call   80101f9f <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
8010200c:	8d 46 01             	lea    0x1(%esi),%eax
8010200f:	ba 00 00 00 00       	mov    $0x0,%edx
80102014:	e8 86 ff ff ff       	call   80101f9f <ioapicwrite>
  for(i = 0; i <= maxintr; i++){
80102019:	83 c3 01             	add    $0x1,%ebx
8010201c:	eb d6                	jmp    80101ff4 <ioapicinit+0x44>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
8010201e:	83 ec 0c             	sub    $0xc,%esp
80102021:	68 9c 68 10 80       	push   $0x8010689c
80102026:	e8 fe e5 ff ff       	call   80100629 <cprintf>
8010202b:	83 c4 10             	add    $0x10,%esp
8010202e:	eb bf                	jmp    80101fef <ioapicinit+0x3f>
  }
}
80102030:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102033:	5b                   	pop    %ebx
80102034:	5e                   	pop    %esi
80102035:	5f                   	pop    %edi
80102036:	5d                   	pop    %ebp
80102037:	c3                   	ret    

80102038 <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80102038:	f3 0f 1e fb          	endbr32 
8010203c:	55                   	push   %ebp
8010203d:	89 e5                	mov    %esp,%ebp
8010203f:	53                   	push   %ebx
80102040:	83 ec 04             	sub    $0x4,%esp
80102043:	8b 45 08             	mov    0x8(%ebp),%eax
  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80102046:	8d 50 20             	lea    0x20(%eax),%edx
80102049:	8d 5c 00 10          	lea    0x10(%eax,%eax,1),%ebx
8010204d:	89 d8                	mov    %ebx,%eax
8010204f:	e8 4b ff ff ff       	call   80101f9f <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
80102054:	8b 55 0c             	mov    0xc(%ebp),%edx
80102057:	c1 e2 18             	shl    $0x18,%edx
8010205a:	8d 43 01             	lea    0x1(%ebx),%eax
8010205d:	e8 3d ff ff ff       	call   80101f9f <ioapicwrite>
}
80102062:	83 c4 04             	add    $0x4,%esp
80102065:	5b                   	pop    %ebx
80102066:	5d                   	pop    %ebp
80102067:	c3                   	ret    

80102068 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80102068:	f3 0f 1e fb          	endbr32 
8010206c:	55                   	push   %ebp
8010206d:	89 e5                	mov    %esp,%ebp
8010206f:	53                   	push   %ebx
80102070:	83 ec 04             	sub    $0x4,%esp
80102073:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct run *r;

  if((uint)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
80102076:	f7 c3 ff 0f 00 00    	test   $0xfff,%ebx
8010207c:	75 4c                	jne    801020ca <kfree+0x62>
8010207e:	81 fb 88 55 11 80    	cmp    $0x80115588,%ebx
80102084:	72 44                	jb     801020ca <kfree+0x62>
80102086:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
8010208c:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80102091:	77 37                	ja     801020ca <kfree+0x62>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80102093:	83 ec 04             	sub    $0x4,%esp
80102096:	68 00 10 00 00       	push   $0x1000
8010209b:	6a 01                	push   $0x1
8010209d:	53                   	push   %ebx
8010209e:	e8 7e 1d 00 00       	call   80103e21 <memset>

  if(kmem.use_lock)
801020a3:	83 c4 10             	add    $0x10,%esp
801020a6:	83 3d d4 46 11 80 00 	cmpl   $0x0,0x801146d4
801020ad:	75 28                	jne    801020d7 <kfree+0x6f>
    acquire(&kmem.lock);
  r = (struct run*)v;
  r->next = kmem.freelist;
801020af:	a1 d8 46 11 80       	mov    0x801146d8,%eax
801020b4:	89 03                	mov    %eax,(%ebx)
  kmem.freelist = r;
801020b6:	89 1d d8 46 11 80    	mov    %ebx,0x801146d8
  if(kmem.use_lock)
801020bc:	83 3d d4 46 11 80 00 	cmpl   $0x0,0x801146d4
801020c3:	75 24                	jne    801020e9 <kfree+0x81>
    release(&kmem.lock);
}
801020c5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801020c8:	c9                   	leave  
801020c9:	c3                   	ret    
    panic("kfree");
801020ca:	83 ec 0c             	sub    $0xc,%esp
801020cd:	68 ce 68 10 80       	push   $0x801068ce
801020d2:	e8 85 e2 ff ff       	call   8010035c <panic>
    acquire(&kmem.lock);
801020d7:	83 ec 0c             	sub    $0xc,%esp
801020da:	68 a0 46 11 80       	push   $0x801146a0
801020df:	e8 89 1c 00 00       	call   80103d6d <acquire>
801020e4:	83 c4 10             	add    $0x10,%esp
801020e7:	eb c6                	jmp    801020af <kfree+0x47>
    release(&kmem.lock);
801020e9:	83 ec 0c             	sub    $0xc,%esp
801020ec:	68 a0 46 11 80       	push   $0x801146a0
801020f1:	e8 e0 1c 00 00       	call   80103dd6 <release>
801020f6:	83 c4 10             	add    $0x10,%esp
}
801020f9:	eb ca                	jmp    801020c5 <kfree+0x5d>

801020fb <freerange>:
{
801020fb:	f3 0f 1e fb          	endbr32 
801020ff:	55                   	push   %ebp
80102100:	89 e5                	mov    %esp,%ebp
80102102:	56                   	push   %esi
80102103:	53                   	push   %ebx
80102104:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  p = (char*)PGROUNDUP((uint)vstart);
80102107:	8b 45 08             	mov    0x8(%ebp),%eax
8010210a:	05 ff 0f 00 00       	add    $0xfff,%eax
8010210f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102114:	8d b0 00 10 00 00    	lea    0x1000(%eax),%esi
8010211a:	39 de                	cmp    %ebx,%esi
8010211c:	77 10                	ja     8010212e <freerange+0x33>
    kfree(p);
8010211e:	83 ec 0c             	sub    $0xc,%esp
80102121:	50                   	push   %eax
80102122:	e8 41 ff ff ff       	call   80102068 <kfree>
80102127:	83 c4 10             	add    $0x10,%esp
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
8010212a:	89 f0                	mov    %esi,%eax
8010212c:	eb e6                	jmp    80102114 <freerange+0x19>
}
8010212e:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102131:	5b                   	pop    %ebx
80102132:	5e                   	pop    %esi
80102133:	5d                   	pop    %ebp
80102134:	c3                   	ret    

80102135 <kinit1>:
{
80102135:	f3 0f 1e fb          	endbr32 
80102139:	55                   	push   %ebp
8010213a:	89 e5                	mov    %esp,%ebp
8010213c:	83 ec 10             	sub    $0x10,%esp
  initlock(&kmem.lock, "kmem");
8010213f:	68 d4 68 10 80       	push   $0x801068d4
80102144:	68 a0 46 11 80       	push   $0x801146a0
80102149:	e8 cf 1a 00 00       	call   80103c1d <initlock>
  kmem.use_lock = 0;
8010214e:	c7 05 d4 46 11 80 00 	movl   $0x0,0x801146d4
80102155:	00 00 00 
  freerange(vstart, vend);
80102158:	83 c4 08             	add    $0x8,%esp
8010215b:	ff 75 0c             	pushl  0xc(%ebp)
8010215e:	ff 75 08             	pushl  0x8(%ebp)
80102161:	e8 95 ff ff ff       	call   801020fb <freerange>
}
80102166:	83 c4 10             	add    $0x10,%esp
80102169:	c9                   	leave  
8010216a:	c3                   	ret    

8010216b <kinit2>:
{
8010216b:	f3 0f 1e fb          	endbr32 
8010216f:	55                   	push   %ebp
80102170:	89 e5                	mov    %esp,%ebp
80102172:	83 ec 10             	sub    $0x10,%esp
  freerange(vstart, vend);
80102175:	ff 75 0c             	pushl  0xc(%ebp)
80102178:	ff 75 08             	pushl  0x8(%ebp)
8010217b:	e8 7b ff ff ff       	call   801020fb <freerange>
  kmem.use_lock = 1;
80102180:	c7 05 d4 46 11 80 01 	movl   $0x1,0x801146d4
80102187:	00 00 00 
}
8010218a:	83 c4 10             	add    $0x10,%esp
8010218d:	c9                   	leave  
8010218e:	c3                   	ret    

8010218f <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
8010218f:	f3 0f 1e fb          	endbr32 
80102193:	55                   	push   %ebp
80102194:	89 e5                	mov    %esp,%ebp
80102196:	53                   	push   %ebx
80102197:	83 ec 04             	sub    $0x4,%esp
  struct run *r;

  if(kmem.use_lock)
8010219a:	83 3d d4 46 11 80 00 	cmpl   $0x0,0x801146d4
801021a1:	75 21                	jne    801021c4 <kalloc+0x35>
    acquire(&kmem.lock);
  r = kmem.freelist;
801021a3:	8b 1d d8 46 11 80    	mov    0x801146d8,%ebx
  if(r)
801021a9:	85 db                	test   %ebx,%ebx
801021ab:	74 07                	je     801021b4 <kalloc+0x25>
    kmem.freelist = r->next;
801021ad:	8b 03                	mov    (%ebx),%eax
801021af:	a3 d8 46 11 80       	mov    %eax,0x801146d8
  if(kmem.use_lock)
801021b4:	83 3d d4 46 11 80 00 	cmpl   $0x0,0x801146d4
801021bb:	75 19                	jne    801021d6 <kalloc+0x47>
    release(&kmem.lock);
  return (char*)r;
}
801021bd:	89 d8                	mov    %ebx,%eax
801021bf:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801021c2:	c9                   	leave  
801021c3:	c3                   	ret    
    acquire(&kmem.lock);
801021c4:	83 ec 0c             	sub    $0xc,%esp
801021c7:	68 a0 46 11 80       	push   $0x801146a0
801021cc:	e8 9c 1b 00 00       	call   80103d6d <acquire>
801021d1:	83 c4 10             	add    $0x10,%esp
801021d4:	eb cd                	jmp    801021a3 <kalloc+0x14>
    release(&kmem.lock);
801021d6:	83 ec 0c             	sub    $0xc,%esp
801021d9:	68 a0 46 11 80       	push   $0x801146a0
801021de:	e8 f3 1b 00 00       	call   80103dd6 <release>
801021e3:	83 c4 10             	add    $0x10,%esp
  return (char*)r;
801021e6:	eb d5                	jmp    801021bd <kalloc+0x2e>

801021e8 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
801021e8:	f3 0f 1e fb          	endbr32 
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801021ec:	ba 64 00 00 00       	mov    $0x64,%edx
801021f1:	ec                   	in     (%dx),%al
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
  if((st & KBS_DIB) == 0)
801021f2:	a8 01                	test   $0x1,%al
801021f4:	0f 84 ad 00 00 00    	je     801022a7 <kbdgetc+0xbf>
801021fa:	ba 60 00 00 00       	mov    $0x60,%edx
801021ff:	ec                   	in     (%dx),%al
    return -1;
  data = inb(KBDATAP);
80102200:	0f b6 d0             	movzbl %al,%edx

  if(data == 0xE0){
80102203:	3c e0                	cmp    $0xe0,%al
80102205:	74 5b                	je     80102262 <kbdgetc+0x7a>
    shift |= E0ESC;
    return 0;
  } else if(data & 0x80){
80102207:	84 c0                	test   %al,%al
80102209:	78 64                	js     8010226f <kbdgetc+0x87>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
    shift &= ~(shiftcode[data] | E0ESC);
    return 0;
  } else if(shift & E0ESC){
8010220b:	8b 0d b4 a5 10 80    	mov    0x8010a5b4,%ecx
80102211:	f6 c1 40             	test   $0x40,%cl
80102214:	74 0f                	je     80102225 <kbdgetc+0x3d>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80102216:	83 c8 80             	or     $0xffffff80,%eax
80102219:	0f b6 d0             	movzbl %al,%edx
    shift &= ~E0ESC;
8010221c:	83 e1 bf             	and    $0xffffffbf,%ecx
8010221f:	89 0d b4 a5 10 80    	mov    %ecx,0x8010a5b4
  }

  shift |= shiftcode[data];
80102225:	0f b6 8a 00 6a 10 80 	movzbl -0x7fef9600(%edx),%ecx
8010222c:	0b 0d b4 a5 10 80    	or     0x8010a5b4,%ecx
  shift ^= togglecode[data];
80102232:	0f b6 82 00 69 10 80 	movzbl -0x7fef9700(%edx),%eax
80102239:	31 c1                	xor    %eax,%ecx
8010223b:	89 0d b4 a5 10 80    	mov    %ecx,0x8010a5b4
  c = charcode[shift & (CTL | SHIFT)][data];
80102241:	89 c8                	mov    %ecx,%eax
80102243:	83 e0 03             	and    $0x3,%eax
80102246:	8b 04 85 e0 68 10 80 	mov    -0x7fef9720(,%eax,4),%eax
8010224d:	0f b6 04 10          	movzbl (%eax,%edx,1),%eax
  if(shift & CAPSLOCK){
80102251:	f6 c1 08             	test   $0x8,%cl
80102254:	74 56                	je     801022ac <kbdgetc+0xc4>
    if('a' <= c && c <= 'z')
80102256:	8d 50 9f             	lea    -0x61(%eax),%edx
80102259:	83 fa 19             	cmp    $0x19,%edx
8010225c:	77 3d                	ja     8010229b <kbdgetc+0xb3>
      c += 'A' - 'a';
8010225e:	83 e8 20             	sub    $0x20,%eax
80102261:	c3                   	ret    
    shift |= E0ESC;
80102262:	83 0d b4 a5 10 80 40 	orl    $0x40,0x8010a5b4
    return 0;
80102269:	b8 00 00 00 00       	mov    $0x0,%eax
8010226e:	c3                   	ret    
    data = (shift & E0ESC ? data : data & 0x7F);
8010226f:	8b 0d b4 a5 10 80    	mov    0x8010a5b4,%ecx
80102275:	f6 c1 40             	test   $0x40,%cl
80102278:	75 05                	jne    8010227f <kbdgetc+0x97>
8010227a:	89 c2                	mov    %eax,%edx
8010227c:	83 e2 7f             	and    $0x7f,%edx
    shift &= ~(shiftcode[data] | E0ESC);
8010227f:	0f b6 82 00 6a 10 80 	movzbl -0x7fef9600(%edx),%eax
80102286:	83 c8 40             	or     $0x40,%eax
80102289:	0f b6 c0             	movzbl %al,%eax
8010228c:	f7 d0                	not    %eax
8010228e:	21 c8                	and    %ecx,%eax
80102290:	a3 b4 a5 10 80       	mov    %eax,0x8010a5b4
    return 0;
80102295:	b8 00 00 00 00       	mov    $0x0,%eax
8010229a:	c3                   	ret    
    else if('A' <= c && c <= 'Z')
8010229b:	8d 50 bf             	lea    -0x41(%eax),%edx
8010229e:	83 fa 19             	cmp    $0x19,%edx
801022a1:	77 09                	ja     801022ac <kbdgetc+0xc4>
      c += 'a' - 'A';
801022a3:	83 c0 20             	add    $0x20,%eax
  }
  return c;
801022a6:	c3                   	ret    
    return -1;
801022a7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801022ac:	c3                   	ret    

801022ad <kbdintr>:

void
kbdintr(void)
{
801022ad:	f3 0f 1e fb          	endbr32 
801022b1:	55                   	push   %ebp
801022b2:	89 e5                	mov    %esp,%ebp
801022b4:	83 ec 14             	sub    $0x14,%esp
  consoleintr(kbdgetc);
801022b7:	68 e8 21 10 80       	push   $0x801021e8
801022bc:	e8 bd e4 ff ff       	call   8010077e <consoleintr>
}
801022c1:	83 c4 10             	add    $0x10,%esp
801022c4:	c9                   	leave  
801022c5:	c3                   	ret    

801022c6 <lapicw>:

//PAGEBREAK!
static void
lapicw(int index, int value)
{
  lapic[index] = value;
801022c6:	8b 0d dc 46 11 80    	mov    0x801146dc,%ecx
801022cc:	8d 04 81             	lea    (%ecx,%eax,4),%eax
801022cf:	89 10                	mov    %edx,(%eax)
  lapic[ID];  // wait for write to finish, by reading
801022d1:	a1 dc 46 11 80       	mov    0x801146dc,%eax
801022d6:	8b 40 20             	mov    0x20(%eax),%eax
}
801022d9:	c3                   	ret    

801022da <cmos_read>:
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801022da:	ba 70 00 00 00       	mov    $0x70,%edx
801022df:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801022e0:	ba 71 00 00 00       	mov    $0x71,%edx
801022e5:	ec                   	in     (%dx),%al
static uint cmos_read(uint reg)
{
  outb(CMOS_PORT,  reg);
  microdelay(200);

  return inb(CMOS_RETURN);
801022e6:	0f b6 c0             	movzbl %al,%eax
}
801022e9:	c3                   	ret    

801022ea <fill_rtcdate>:

static void fill_rtcdate(struct rtcdate *r)
{
801022ea:	55                   	push   %ebp
801022eb:	89 e5                	mov    %esp,%ebp
801022ed:	53                   	push   %ebx
801022ee:	83 ec 04             	sub    $0x4,%esp
801022f1:	89 c3                	mov    %eax,%ebx
  r->second = cmos_read(SECS);
801022f3:	b8 00 00 00 00       	mov    $0x0,%eax
801022f8:	e8 dd ff ff ff       	call   801022da <cmos_read>
801022fd:	89 03                	mov    %eax,(%ebx)
  r->minute = cmos_read(MINS);
801022ff:	b8 02 00 00 00       	mov    $0x2,%eax
80102304:	e8 d1 ff ff ff       	call   801022da <cmos_read>
80102309:	89 43 04             	mov    %eax,0x4(%ebx)
  r->hour   = cmos_read(HOURS);
8010230c:	b8 04 00 00 00       	mov    $0x4,%eax
80102311:	e8 c4 ff ff ff       	call   801022da <cmos_read>
80102316:	89 43 08             	mov    %eax,0x8(%ebx)
  r->day    = cmos_read(DAY);
80102319:	b8 07 00 00 00       	mov    $0x7,%eax
8010231e:	e8 b7 ff ff ff       	call   801022da <cmos_read>
80102323:	89 43 0c             	mov    %eax,0xc(%ebx)
  r->month  = cmos_read(MONTH);
80102326:	b8 08 00 00 00       	mov    $0x8,%eax
8010232b:	e8 aa ff ff ff       	call   801022da <cmos_read>
80102330:	89 43 10             	mov    %eax,0x10(%ebx)
  r->year   = cmos_read(YEAR);
80102333:	b8 09 00 00 00       	mov    $0x9,%eax
80102338:	e8 9d ff ff ff       	call   801022da <cmos_read>
8010233d:	89 43 14             	mov    %eax,0x14(%ebx)
}
80102340:	83 c4 04             	add    $0x4,%esp
80102343:	5b                   	pop    %ebx
80102344:	5d                   	pop    %ebp
80102345:	c3                   	ret    

80102346 <lapicinit>:
{
80102346:	f3 0f 1e fb          	endbr32 
  if(!lapic)
8010234a:	83 3d dc 46 11 80 00 	cmpl   $0x0,0x801146dc
80102351:	0f 84 fe 00 00 00    	je     80102455 <lapicinit+0x10f>
{
80102357:	55                   	push   %ebp
80102358:	89 e5                	mov    %esp,%ebp
8010235a:	83 ec 08             	sub    $0x8,%esp
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
8010235d:	ba 3f 01 00 00       	mov    $0x13f,%edx
80102362:	b8 3c 00 00 00       	mov    $0x3c,%eax
80102367:	e8 5a ff ff ff       	call   801022c6 <lapicw>
  lapicw(TDCR, X1);
8010236c:	ba 0b 00 00 00       	mov    $0xb,%edx
80102371:	b8 f8 00 00 00       	mov    $0xf8,%eax
80102376:	e8 4b ff ff ff       	call   801022c6 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
8010237b:	ba 20 00 02 00       	mov    $0x20020,%edx
80102380:	b8 c8 00 00 00       	mov    $0xc8,%eax
80102385:	e8 3c ff ff ff       	call   801022c6 <lapicw>
  lapicw(TICR, 1000000);
8010238a:	ba 40 42 0f 00       	mov    $0xf4240,%edx
8010238f:	b8 e0 00 00 00       	mov    $0xe0,%eax
80102394:	e8 2d ff ff ff       	call   801022c6 <lapicw>
  lapicw(LINT0, MASKED);
80102399:	ba 00 00 01 00       	mov    $0x10000,%edx
8010239e:	b8 d4 00 00 00       	mov    $0xd4,%eax
801023a3:	e8 1e ff ff ff       	call   801022c6 <lapicw>
  lapicw(LINT1, MASKED);
801023a8:	ba 00 00 01 00       	mov    $0x10000,%edx
801023ad:	b8 d8 00 00 00       	mov    $0xd8,%eax
801023b2:	e8 0f ff ff ff       	call   801022c6 <lapicw>
  if(((lapic[VER]>>16) & 0xFF) >= 4)
801023b7:	a1 dc 46 11 80       	mov    0x801146dc,%eax
801023bc:	8b 40 30             	mov    0x30(%eax),%eax
801023bf:	c1 e8 10             	shr    $0x10,%eax
801023c2:	a8 fc                	test   $0xfc,%al
801023c4:	75 7b                	jne    80102441 <lapicinit+0xfb>
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
801023c6:	ba 33 00 00 00       	mov    $0x33,%edx
801023cb:	b8 dc 00 00 00       	mov    $0xdc,%eax
801023d0:	e8 f1 fe ff ff       	call   801022c6 <lapicw>
  lapicw(ESR, 0);
801023d5:	ba 00 00 00 00       	mov    $0x0,%edx
801023da:	b8 a0 00 00 00       	mov    $0xa0,%eax
801023df:	e8 e2 fe ff ff       	call   801022c6 <lapicw>
  lapicw(ESR, 0);
801023e4:	ba 00 00 00 00       	mov    $0x0,%edx
801023e9:	b8 a0 00 00 00       	mov    $0xa0,%eax
801023ee:	e8 d3 fe ff ff       	call   801022c6 <lapicw>
  lapicw(EOI, 0);
801023f3:	ba 00 00 00 00       	mov    $0x0,%edx
801023f8:	b8 2c 00 00 00       	mov    $0x2c,%eax
801023fd:	e8 c4 fe ff ff       	call   801022c6 <lapicw>
  lapicw(ICRHI, 0);
80102402:	ba 00 00 00 00       	mov    $0x0,%edx
80102407:	b8 c4 00 00 00       	mov    $0xc4,%eax
8010240c:	e8 b5 fe ff ff       	call   801022c6 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
80102411:	ba 00 85 08 00       	mov    $0x88500,%edx
80102416:	b8 c0 00 00 00       	mov    $0xc0,%eax
8010241b:	e8 a6 fe ff ff       	call   801022c6 <lapicw>
  while(lapic[ICRLO] & DELIVS)
80102420:	a1 dc 46 11 80       	mov    0x801146dc,%eax
80102425:	8b 80 00 03 00 00    	mov    0x300(%eax),%eax
8010242b:	f6 c4 10             	test   $0x10,%ah
8010242e:	75 f0                	jne    80102420 <lapicinit+0xda>
  lapicw(TPR, 0);
80102430:	ba 00 00 00 00       	mov    $0x0,%edx
80102435:	b8 20 00 00 00       	mov    $0x20,%eax
8010243a:	e8 87 fe ff ff       	call   801022c6 <lapicw>
}
8010243f:	c9                   	leave  
80102440:	c3                   	ret    
    lapicw(PCINT, MASKED);
80102441:	ba 00 00 01 00       	mov    $0x10000,%edx
80102446:	b8 d0 00 00 00       	mov    $0xd0,%eax
8010244b:	e8 76 fe ff ff       	call   801022c6 <lapicw>
80102450:	e9 71 ff ff ff       	jmp    801023c6 <lapicinit+0x80>
80102455:	c3                   	ret    

80102456 <lapicid>:
{
80102456:	f3 0f 1e fb          	endbr32 
  if (!lapic)
8010245a:	a1 dc 46 11 80       	mov    0x801146dc,%eax
8010245f:	85 c0                	test   %eax,%eax
80102461:	74 07                	je     8010246a <lapicid+0x14>
  return lapic[ID] >> 24;
80102463:	8b 40 20             	mov    0x20(%eax),%eax
80102466:	c1 e8 18             	shr    $0x18,%eax
80102469:	c3                   	ret    
    return 0;
8010246a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010246f:	c3                   	ret    

80102470 <lapiceoi>:
{
80102470:	f3 0f 1e fb          	endbr32 
  if(lapic)
80102474:	83 3d dc 46 11 80 00 	cmpl   $0x0,0x801146dc
8010247b:	74 17                	je     80102494 <lapiceoi+0x24>
{
8010247d:	55                   	push   %ebp
8010247e:	89 e5                	mov    %esp,%ebp
80102480:	83 ec 08             	sub    $0x8,%esp
    lapicw(EOI, 0);
80102483:	ba 00 00 00 00       	mov    $0x0,%edx
80102488:	b8 2c 00 00 00       	mov    $0x2c,%eax
8010248d:	e8 34 fe ff ff       	call   801022c6 <lapicw>
}
80102492:	c9                   	leave  
80102493:	c3                   	ret    
80102494:	c3                   	ret    

80102495 <microdelay>:
{
80102495:	f3 0f 1e fb          	endbr32 
}
80102499:	c3                   	ret    

8010249a <lapicstartap>:
{
8010249a:	f3 0f 1e fb          	endbr32 
8010249e:	55                   	push   %ebp
8010249f:	89 e5                	mov    %esp,%ebp
801024a1:	57                   	push   %edi
801024a2:	56                   	push   %esi
801024a3:	53                   	push   %ebx
801024a4:	83 ec 0c             	sub    $0xc,%esp
801024a7:	8b 75 08             	mov    0x8(%ebp),%esi
801024aa:	8b 7d 0c             	mov    0xc(%ebp),%edi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801024ad:	b8 0f 00 00 00       	mov    $0xf,%eax
801024b2:	ba 70 00 00 00       	mov    $0x70,%edx
801024b7:	ee                   	out    %al,(%dx)
801024b8:	b8 0a 00 00 00       	mov    $0xa,%eax
801024bd:	ba 71 00 00 00       	mov    $0x71,%edx
801024c2:	ee                   	out    %al,(%dx)
  wrv[0] = 0;
801024c3:	66 c7 05 67 04 00 80 	movw   $0x0,0x80000467
801024ca:	00 00 
  wrv[1] = addr >> 4;
801024cc:	89 f8                	mov    %edi,%eax
801024ce:	c1 e8 04             	shr    $0x4,%eax
801024d1:	66 a3 69 04 00 80    	mov    %ax,0x80000469
  lapicw(ICRHI, apicid<<24);
801024d7:	c1 e6 18             	shl    $0x18,%esi
801024da:	89 f2                	mov    %esi,%edx
801024dc:	b8 c4 00 00 00       	mov    $0xc4,%eax
801024e1:	e8 e0 fd ff ff       	call   801022c6 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
801024e6:	ba 00 c5 00 00       	mov    $0xc500,%edx
801024eb:	b8 c0 00 00 00       	mov    $0xc0,%eax
801024f0:	e8 d1 fd ff ff       	call   801022c6 <lapicw>
  lapicw(ICRLO, INIT | LEVEL);
801024f5:	ba 00 85 00 00       	mov    $0x8500,%edx
801024fa:	b8 c0 00 00 00       	mov    $0xc0,%eax
801024ff:	e8 c2 fd ff ff       	call   801022c6 <lapicw>
  for(i = 0; i < 2; i++){
80102504:	bb 00 00 00 00       	mov    $0x0,%ebx
80102509:	eb 21                	jmp    8010252c <lapicstartap+0x92>
    lapicw(ICRHI, apicid<<24);
8010250b:	89 f2                	mov    %esi,%edx
8010250d:	b8 c4 00 00 00       	mov    $0xc4,%eax
80102512:	e8 af fd ff ff       	call   801022c6 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
80102517:	89 fa                	mov    %edi,%edx
80102519:	c1 ea 0c             	shr    $0xc,%edx
8010251c:	80 ce 06             	or     $0x6,%dh
8010251f:	b8 c0 00 00 00       	mov    $0xc0,%eax
80102524:	e8 9d fd ff ff       	call   801022c6 <lapicw>
  for(i = 0; i < 2; i++){
80102529:	83 c3 01             	add    $0x1,%ebx
8010252c:	83 fb 01             	cmp    $0x1,%ebx
8010252f:	7e da                	jle    8010250b <lapicstartap+0x71>
}
80102531:	83 c4 0c             	add    $0xc,%esp
80102534:	5b                   	pop    %ebx
80102535:	5e                   	pop    %esi
80102536:	5f                   	pop    %edi
80102537:	5d                   	pop    %ebp
80102538:	c3                   	ret    

80102539 <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void cmostime(struct rtcdate *r)
{
80102539:	f3 0f 1e fb          	endbr32 
8010253d:	55                   	push   %ebp
8010253e:	89 e5                	mov    %esp,%ebp
80102540:	57                   	push   %edi
80102541:	56                   	push   %esi
80102542:	53                   	push   %ebx
80102543:	83 ec 3c             	sub    $0x3c,%esp
80102546:	8b 75 08             	mov    0x8(%ebp),%esi
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
80102549:	b8 0b 00 00 00       	mov    $0xb,%eax
8010254e:	e8 87 fd ff ff       	call   801022da <cmos_read>

  bcd = (sb & (1 << 2)) == 0;
80102553:	83 e0 04             	and    $0x4,%eax
80102556:	89 c7                	mov    %eax,%edi

  // make sure CMOS doesn't modify time while we read it
  for(;;) {
    fill_rtcdate(&t1);
80102558:	8d 45 d0             	lea    -0x30(%ebp),%eax
8010255b:	e8 8a fd ff ff       	call   801022ea <fill_rtcdate>
    if(cmos_read(CMOS_STATA) & CMOS_UIP)
80102560:	b8 0a 00 00 00       	mov    $0xa,%eax
80102565:	e8 70 fd ff ff       	call   801022da <cmos_read>
8010256a:	a8 80                	test   $0x80,%al
8010256c:	75 ea                	jne    80102558 <cmostime+0x1f>
        continue;
    fill_rtcdate(&t2);
8010256e:	8d 5d b8             	lea    -0x48(%ebp),%ebx
80102571:	89 d8                	mov    %ebx,%eax
80102573:	e8 72 fd ff ff       	call   801022ea <fill_rtcdate>
    if(memcmp(&t1, &t2, sizeof(t1)) == 0)
80102578:	83 ec 04             	sub    $0x4,%esp
8010257b:	6a 18                	push   $0x18
8010257d:	53                   	push   %ebx
8010257e:	8d 45 d0             	lea    -0x30(%ebp),%eax
80102581:	50                   	push   %eax
80102582:	e8 e1 18 00 00       	call   80103e68 <memcmp>
80102587:	83 c4 10             	add    $0x10,%esp
8010258a:	85 c0                	test   %eax,%eax
8010258c:	75 ca                	jne    80102558 <cmostime+0x1f>
      break;
  }

  // convert
  if(bcd) {
8010258e:	85 ff                	test   %edi,%edi
80102590:	75 78                	jne    8010260a <cmostime+0xd1>
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
80102592:	8b 45 d0             	mov    -0x30(%ebp),%eax
80102595:	89 c2                	mov    %eax,%edx
80102597:	c1 ea 04             	shr    $0x4,%edx
8010259a:	8d 14 92             	lea    (%edx,%edx,4),%edx
8010259d:	83 e0 0f             	and    $0xf,%eax
801025a0:	8d 04 50             	lea    (%eax,%edx,2),%eax
801025a3:	89 45 d0             	mov    %eax,-0x30(%ebp)
    CONV(minute);
801025a6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
801025a9:	89 c2                	mov    %eax,%edx
801025ab:	c1 ea 04             	shr    $0x4,%edx
801025ae:	8d 14 92             	lea    (%edx,%edx,4),%edx
801025b1:	83 e0 0f             	and    $0xf,%eax
801025b4:	8d 04 50             	lea    (%eax,%edx,2),%eax
801025b7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    CONV(hour  );
801025ba:	8b 45 d8             	mov    -0x28(%ebp),%eax
801025bd:	89 c2                	mov    %eax,%edx
801025bf:	c1 ea 04             	shr    $0x4,%edx
801025c2:	8d 14 92             	lea    (%edx,%edx,4),%edx
801025c5:	83 e0 0f             	and    $0xf,%eax
801025c8:	8d 04 50             	lea    (%eax,%edx,2),%eax
801025cb:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(day   );
801025ce:	8b 45 dc             	mov    -0x24(%ebp),%eax
801025d1:	89 c2                	mov    %eax,%edx
801025d3:	c1 ea 04             	shr    $0x4,%edx
801025d6:	8d 14 92             	lea    (%edx,%edx,4),%edx
801025d9:	83 e0 0f             	and    $0xf,%eax
801025dc:	8d 04 50             	lea    (%eax,%edx,2),%eax
801025df:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(month );
801025e2:	8b 45 e0             	mov    -0x20(%ebp),%eax
801025e5:	89 c2                	mov    %eax,%edx
801025e7:	c1 ea 04             	shr    $0x4,%edx
801025ea:	8d 14 92             	lea    (%edx,%edx,4),%edx
801025ed:	83 e0 0f             	and    $0xf,%eax
801025f0:	8d 04 50             	lea    (%eax,%edx,2),%eax
801025f3:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(year  );
801025f6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801025f9:	89 c2                	mov    %eax,%edx
801025fb:	c1 ea 04             	shr    $0x4,%edx
801025fe:	8d 14 92             	lea    (%edx,%edx,4),%edx
80102601:	83 e0 0f             	and    $0xf,%eax
80102604:	8d 04 50             	lea    (%eax,%edx,2),%eax
80102607:	89 45 e4             	mov    %eax,-0x1c(%ebp)
#undef     CONV
  }

  *r = t1;
8010260a:	8b 45 d0             	mov    -0x30(%ebp),%eax
8010260d:	89 06                	mov    %eax,(%esi)
8010260f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80102612:	89 46 04             	mov    %eax,0x4(%esi)
80102615:	8b 45 d8             	mov    -0x28(%ebp),%eax
80102618:	89 46 08             	mov    %eax,0x8(%esi)
8010261b:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010261e:	89 46 0c             	mov    %eax,0xc(%esi)
80102621:	8b 45 e0             	mov    -0x20(%ebp),%eax
80102624:	89 46 10             	mov    %eax,0x10(%esi)
80102627:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010262a:	89 46 14             	mov    %eax,0x14(%esi)
  r->year += 2000;
8010262d:	81 46 14 d0 07 00 00 	addl   $0x7d0,0x14(%esi)
}
80102634:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102637:	5b                   	pop    %ebx
80102638:	5e                   	pop    %esi
80102639:	5f                   	pop    %edi
8010263a:	5d                   	pop    %ebp
8010263b:	c3                   	ret    

8010263c <read_head>:
}

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
8010263c:	55                   	push   %ebp
8010263d:	89 e5                	mov    %esp,%ebp
8010263f:	53                   	push   %ebx
80102640:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
80102643:	ff 35 14 47 11 80    	pushl  0x80114714
80102649:	ff 35 24 47 11 80    	pushl  0x80114724
8010264f:	e8 1c db ff ff       	call   80100170 <bread>
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
80102654:	8b 58 5c             	mov    0x5c(%eax),%ebx
80102657:	89 1d 28 47 11 80    	mov    %ebx,0x80114728
  for (i = 0; i < log.lh.n; i++) {
8010265d:	83 c4 10             	add    $0x10,%esp
80102660:	ba 00 00 00 00       	mov    $0x0,%edx
80102665:	39 d3                	cmp    %edx,%ebx
80102667:	7e 10                	jle    80102679 <read_head+0x3d>
    log.lh.block[i] = lh->block[i];
80102669:	8b 4c 90 60          	mov    0x60(%eax,%edx,4),%ecx
8010266d:	89 0c 95 2c 47 11 80 	mov    %ecx,-0x7feeb8d4(,%edx,4)
  for (i = 0; i < log.lh.n; i++) {
80102674:	83 c2 01             	add    $0x1,%edx
80102677:	eb ec                	jmp    80102665 <read_head+0x29>
  }
  brelse(buf);
80102679:	83 ec 0c             	sub    $0xc,%esp
8010267c:	50                   	push   %eax
8010267d:	e8 5f db ff ff       	call   801001e1 <brelse>
}
80102682:	83 c4 10             	add    $0x10,%esp
80102685:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102688:	c9                   	leave  
80102689:	c3                   	ret    

8010268a <install_trans>:
{
8010268a:	55                   	push   %ebp
8010268b:	89 e5                	mov    %esp,%ebp
8010268d:	57                   	push   %edi
8010268e:	56                   	push   %esi
8010268f:	53                   	push   %ebx
80102690:	83 ec 0c             	sub    $0xc,%esp
  for (tail = 0; tail < log.lh.n; tail++) {
80102693:	be 00 00 00 00       	mov    $0x0,%esi
80102698:	39 35 28 47 11 80    	cmp    %esi,0x80114728
8010269e:	7e 68                	jle    80102708 <install_trans+0x7e>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
801026a0:	89 f0                	mov    %esi,%eax
801026a2:	03 05 14 47 11 80    	add    0x80114714,%eax
801026a8:	83 c0 01             	add    $0x1,%eax
801026ab:	83 ec 08             	sub    $0x8,%esp
801026ae:	50                   	push   %eax
801026af:	ff 35 24 47 11 80    	pushl  0x80114724
801026b5:	e8 b6 da ff ff       	call   80100170 <bread>
801026ba:	89 c7                	mov    %eax,%edi
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
801026bc:	83 c4 08             	add    $0x8,%esp
801026bf:	ff 34 b5 2c 47 11 80 	pushl  -0x7feeb8d4(,%esi,4)
801026c6:	ff 35 24 47 11 80    	pushl  0x80114724
801026cc:	e8 9f da ff ff       	call   80100170 <bread>
801026d1:	89 c3                	mov    %eax,%ebx
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
801026d3:	8d 57 5c             	lea    0x5c(%edi),%edx
801026d6:	8d 40 5c             	lea    0x5c(%eax),%eax
801026d9:	83 c4 0c             	add    $0xc,%esp
801026dc:	68 00 02 00 00       	push   $0x200
801026e1:	52                   	push   %edx
801026e2:	50                   	push   %eax
801026e3:	e8 b9 17 00 00       	call   80103ea1 <memmove>
    bwrite(dbuf);  // write dst to disk
801026e8:	89 1c 24             	mov    %ebx,(%esp)
801026eb:	e8 b2 da ff ff       	call   801001a2 <bwrite>
    brelse(lbuf);
801026f0:	89 3c 24             	mov    %edi,(%esp)
801026f3:	e8 e9 da ff ff       	call   801001e1 <brelse>
    brelse(dbuf);
801026f8:	89 1c 24             	mov    %ebx,(%esp)
801026fb:	e8 e1 da ff ff       	call   801001e1 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
80102700:	83 c6 01             	add    $0x1,%esi
80102703:	83 c4 10             	add    $0x10,%esp
80102706:	eb 90                	jmp    80102698 <install_trans+0xe>
}
80102708:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010270b:	5b                   	pop    %ebx
8010270c:	5e                   	pop    %esi
8010270d:	5f                   	pop    %edi
8010270e:	5d                   	pop    %ebp
8010270f:	c3                   	ret    

80102710 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80102710:	55                   	push   %ebp
80102711:	89 e5                	mov    %esp,%ebp
80102713:	53                   	push   %ebx
80102714:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
80102717:	ff 35 14 47 11 80    	pushl  0x80114714
8010271d:	ff 35 24 47 11 80    	pushl  0x80114724
80102723:	e8 48 da ff ff       	call   80100170 <bread>
80102728:	89 c3                	mov    %eax,%ebx
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
8010272a:	8b 0d 28 47 11 80    	mov    0x80114728,%ecx
80102730:	89 48 5c             	mov    %ecx,0x5c(%eax)
  for (i = 0; i < log.lh.n; i++) {
80102733:	83 c4 10             	add    $0x10,%esp
80102736:	b8 00 00 00 00       	mov    $0x0,%eax
8010273b:	39 c1                	cmp    %eax,%ecx
8010273d:	7e 10                	jle    8010274f <write_head+0x3f>
    hb->block[i] = log.lh.block[i];
8010273f:	8b 14 85 2c 47 11 80 	mov    -0x7feeb8d4(,%eax,4),%edx
80102746:	89 54 83 60          	mov    %edx,0x60(%ebx,%eax,4)
  for (i = 0; i < log.lh.n; i++) {
8010274a:	83 c0 01             	add    $0x1,%eax
8010274d:	eb ec                	jmp    8010273b <write_head+0x2b>
  }
  bwrite(buf);
8010274f:	83 ec 0c             	sub    $0xc,%esp
80102752:	53                   	push   %ebx
80102753:	e8 4a da ff ff       	call   801001a2 <bwrite>
  brelse(buf);
80102758:	89 1c 24             	mov    %ebx,(%esp)
8010275b:	e8 81 da ff ff       	call   801001e1 <brelse>
}
80102760:	83 c4 10             	add    $0x10,%esp
80102763:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102766:	c9                   	leave  
80102767:	c3                   	ret    

80102768 <recover_from_log>:

static void
recover_from_log(void)
{
80102768:	55                   	push   %ebp
80102769:	89 e5                	mov    %esp,%ebp
8010276b:	83 ec 08             	sub    $0x8,%esp
  read_head();
8010276e:	e8 c9 fe ff ff       	call   8010263c <read_head>
  install_trans(); // if committed, copy from log to disk
80102773:	e8 12 ff ff ff       	call   8010268a <install_trans>
  log.lh.n = 0;
80102778:	c7 05 28 47 11 80 00 	movl   $0x0,0x80114728
8010277f:	00 00 00 
  write_head(); // clear the log
80102782:	e8 89 ff ff ff       	call   80102710 <write_head>
}
80102787:	c9                   	leave  
80102788:	c3                   	ret    

80102789 <write_log>:
}

// Copy modified blocks from cache to log.
static void
write_log(void)
{
80102789:	55                   	push   %ebp
8010278a:	89 e5                	mov    %esp,%ebp
8010278c:	57                   	push   %edi
8010278d:	56                   	push   %esi
8010278e:	53                   	push   %ebx
8010278f:	83 ec 0c             	sub    $0xc,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80102792:	be 00 00 00 00       	mov    $0x0,%esi
80102797:	39 35 28 47 11 80    	cmp    %esi,0x80114728
8010279d:	7e 68                	jle    80102807 <write_log+0x7e>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
8010279f:	89 f0                	mov    %esi,%eax
801027a1:	03 05 14 47 11 80    	add    0x80114714,%eax
801027a7:	83 c0 01             	add    $0x1,%eax
801027aa:	83 ec 08             	sub    $0x8,%esp
801027ad:	50                   	push   %eax
801027ae:	ff 35 24 47 11 80    	pushl  0x80114724
801027b4:	e8 b7 d9 ff ff       	call   80100170 <bread>
801027b9:	89 c3                	mov    %eax,%ebx
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
801027bb:	83 c4 08             	add    $0x8,%esp
801027be:	ff 34 b5 2c 47 11 80 	pushl  -0x7feeb8d4(,%esi,4)
801027c5:	ff 35 24 47 11 80    	pushl  0x80114724
801027cb:	e8 a0 d9 ff ff       	call   80100170 <bread>
801027d0:	89 c7                	mov    %eax,%edi
    memmove(to->data, from->data, BSIZE);
801027d2:	8d 50 5c             	lea    0x5c(%eax),%edx
801027d5:	8d 43 5c             	lea    0x5c(%ebx),%eax
801027d8:	83 c4 0c             	add    $0xc,%esp
801027db:	68 00 02 00 00       	push   $0x200
801027e0:	52                   	push   %edx
801027e1:	50                   	push   %eax
801027e2:	e8 ba 16 00 00       	call   80103ea1 <memmove>
    bwrite(to);  // write the log
801027e7:	89 1c 24             	mov    %ebx,(%esp)
801027ea:	e8 b3 d9 ff ff       	call   801001a2 <bwrite>
    brelse(from);
801027ef:	89 3c 24             	mov    %edi,(%esp)
801027f2:	e8 ea d9 ff ff       	call   801001e1 <brelse>
    brelse(to);
801027f7:	89 1c 24             	mov    %ebx,(%esp)
801027fa:	e8 e2 d9 ff ff       	call   801001e1 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
801027ff:	83 c6 01             	add    $0x1,%esi
80102802:	83 c4 10             	add    $0x10,%esp
80102805:	eb 90                	jmp    80102797 <write_log+0xe>
  }
}
80102807:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010280a:	5b                   	pop    %ebx
8010280b:	5e                   	pop    %esi
8010280c:	5f                   	pop    %edi
8010280d:	5d                   	pop    %ebp
8010280e:	c3                   	ret    

8010280f <commit>:

static void
commit()
{
  if (log.lh.n > 0) {
8010280f:	83 3d 28 47 11 80 00 	cmpl   $0x0,0x80114728
80102816:	7f 01                	jg     80102819 <commit+0xa>
80102818:	c3                   	ret    
{
80102819:	55                   	push   %ebp
8010281a:	89 e5                	mov    %esp,%ebp
8010281c:	83 ec 08             	sub    $0x8,%esp
    write_log();     // Write modified blocks from cache to log
8010281f:	e8 65 ff ff ff       	call   80102789 <write_log>
    write_head();    // Write header to disk -- the real commit
80102824:	e8 e7 fe ff ff       	call   80102710 <write_head>
    install_trans(); // Now install writes to home locations
80102829:	e8 5c fe ff ff       	call   8010268a <install_trans>
    log.lh.n = 0;
8010282e:	c7 05 28 47 11 80 00 	movl   $0x0,0x80114728
80102835:	00 00 00 
    write_head();    // Erase the transaction from the log
80102838:	e8 d3 fe ff ff       	call   80102710 <write_head>
  }
}
8010283d:	c9                   	leave  
8010283e:	c3                   	ret    

8010283f <initlog>:
{
8010283f:	f3 0f 1e fb          	endbr32 
80102843:	55                   	push   %ebp
80102844:	89 e5                	mov    %esp,%ebp
80102846:	53                   	push   %ebx
80102847:	83 ec 2c             	sub    $0x2c,%esp
8010284a:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&log.lock, "log");
8010284d:	68 00 6b 10 80       	push   $0x80106b00
80102852:	68 e0 46 11 80       	push   $0x801146e0
80102857:	e8 c1 13 00 00       	call   80103c1d <initlock>
  readsb(dev, &sb);
8010285c:	83 c4 08             	add    $0x8,%esp
8010285f:	8d 45 dc             	lea    -0x24(%ebp),%eax
80102862:	50                   	push   %eax
80102863:	53                   	push   %ebx
80102864:	e8 3b ea ff ff       	call   801012a4 <readsb>
  log.start = sb.logstart;
80102869:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010286c:	a3 14 47 11 80       	mov    %eax,0x80114714
  log.size = sb.nlog;
80102871:	8b 45 e8             	mov    -0x18(%ebp),%eax
80102874:	a3 18 47 11 80       	mov    %eax,0x80114718
  log.dev = dev;
80102879:	89 1d 24 47 11 80    	mov    %ebx,0x80114724
  recover_from_log();
8010287f:	e8 e4 fe ff ff       	call   80102768 <recover_from_log>
}
80102884:	83 c4 10             	add    $0x10,%esp
80102887:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010288a:	c9                   	leave  
8010288b:	c3                   	ret    

8010288c <begin_op>:
{
8010288c:	f3 0f 1e fb          	endbr32 
80102890:	55                   	push   %ebp
80102891:	89 e5                	mov    %esp,%ebp
80102893:	83 ec 14             	sub    $0x14,%esp
  acquire(&log.lock);
80102896:	68 e0 46 11 80       	push   $0x801146e0
8010289b:	e8 cd 14 00 00       	call   80103d6d <acquire>
801028a0:	83 c4 10             	add    $0x10,%esp
801028a3:	eb 15                	jmp    801028ba <begin_op+0x2e>
      sleep(&log, &log.lock);
801028a5:	83 ec 08             	sub    $0x8,%esp
801028a8:	68 e0 46 11 80       	push   $0x801146e0
801028ad:	68 e0 46 11 80       	push   $0x801146e0
801028b2:	e8 49 0f 00 00       	call   80103800 <sleep>
801028b7:	83 c4 10             	add    $0x10,%esp
    if(log.committing){
801028ba:	83 3d 20 47 11 80 00 	cmpl   $0x0,0x80114720
801028c1:	75 e2                	jne    801028a5 <begin_op+0x19>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
801028c3:	a1 1c 47 11 80       	mov    0x8011471c,%eax
801028c8:	83 c0 01             	add    $0x1,%eax
801028cb:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801028ce:	8d 14 09             	lea    (%ecx,%ecx,1),%edx
801028d1:	03 15 28 47 11 80    	add    0x80114728,%edx
801028d7:	83 fa 1e             	cmp    $0x1e,%edx
801028da:	7e 17                	jle    801028f3 <begin_op+0x67>
      sleep(&log, &log.lock);
801028dc:	83 ec 08             	sub    $0x8,%esp
801028df:	68 e0 46 11 80       	push   $0x801146e0
801028e4:	68 e0 46 11 80       	push   $0x801146e0
801028e9:	e8 12 0f 00 00       	call   80103800 <sleep>
801028ee:	83 c4 10             	add    $0x10,%esp
801028f1:	eb c7                	jmp    801028ba <begin_op+0x2e>
      log.outstanding += 1;
801028f3:	a3 1c 47 11 80       	mov    %eax,0x8011471c
      release(&log.lock);
801028f8:	83 ec 0c             	sub    $0xc,%esp
801028fb:	68 e0 46 11 80       	push   $0x801146e0
80102900:	e8 d1 14 00 00       	call   80103dd6 <release>
}
80102905:	83 c4 10             	add    $0x10,%esp
80102908:	c9                   	leave  
80102909:	c3                   	ret    

8010290a <end_op>:
{
8010290a:	f3 0f 1e fb          	endbr32 
8010290e:	55                   	push   %ebp
8010290f:	89 e5                	mov    %esp,%ebp
80102911:	53                   	push   %ebx
80102912:	83 ec 10             	sub    $0x10,%esp
  acquire(&log.lock);
80102915:	68 e0 46 11 80       	push   $0x801146e0
8010291a:	e8 4e 14 00 00       	call   80103d6d <acquire>
  log.outstanding -= 1;
8010291f:	a1 1c 47 11 80       	mov    0x8011471c,%eax
80102924:	83 e8 01             	sub    $0x1,%eax
80102927:	a3 1c 47 11 80       	mov    %eax,0x8011471c
  if(log.committing)
8010292c:	8b 1d 20 47 11 80    	mov    0x80114720,%ebx
80102932:	83 c4 10             	add    $0x10,%esp
80102935:	85 db                	test   %ebx,%ebx
80102937:	75 2c                	jne    80102965 <end_op+0x5b>
  if(log.outstanding == 0){
80102939:	85 c0                	test   %eax,%eax
8010293b:	75 35                	jne    80102972 <end_op+0x68>
    log.committing = 1;
8010293d:	c7 05 20 47 11 80 01 	movl   $0x1,0x80114720
80102944:	00 00 00 
    do_commit = 1;
80102947:	bb 01 00 00 00       	mov    $0x1,%ebx
  release(&log.lock);
8010294c:	83 ec 0c             	sub    $0xc,%esp
8010294f:	68 e0 46 11 80       	push   $0x801146e0
80102954:	e8 7d 14 00 00       	call   80103dd6 <release>
  if(do_commit){
80102959:	83 c4 10             	add    $0x10,%esp
8010295c:	85 db                	test   %ebx,%ebx
8010295e:	75 24                	jne    80102984 <end_op+0x7a>
}
80102960:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102963:	c9                   	leave  
80102964:	c3                   	ret    
    panic("log.committing");
80102965:	83 ec 0c             	sub    $0xc,%esp
80102968:	68 04 6b 10 80       	push   $0x80106b04
8010296d:	e8 ea d9 ff ff       	call   8010035c <panic>
    wakeup(&log);
80102972:	83 ec 0c             	sub    $0xc,%esp
80102975:	68 e0 46 11 80       	push   $0x801146e0
8010297a:	e8 ed 0f 00 00       	call   8010396c <wakeup>
8010297f:	83 c4 10             	add    $0x10,%esp
80102982:	eb c8                	jmp    8010294c <end_op+0x42>
    commit();
80102984:	e8 86 fe ff ff       	call   8010280f <commit>
    acquire(&log.lock);
80102989:	83 ec 0c             	sub    $0xc,%esp
8010298c:	68 e0 46 11 80       	push   $0x801146e0
80102991:	e8 d7 13 00 00       	call   80103d6d <acquire>
    log.committing = 0;
80102996:	c7 05 20 47 11 80 00 	movl   $0x0,0x80114720
8010299d:	00 00 00 
    wakeup(&log);
801029a0:	c7 04 24 e0 46 11 80 	movl   $0x801146e0,(%esp)
801029a7:	e8 c0 0f 00 00       	call   8010396c <wakeup>
    release(&log.lock);
801029ac:	c7 04 24 e0 46 11 80 	movl   $0x801146e0,(%esp)
801029b3:	e8 1e 14 00 00       	call   80103dd6 <release>
801029b8:	83 c4 10             	add    $0x10,%esp
}
801029bb:	eb a3                	jmp    80102960 <end_op+0x56>

801029bd <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
801029bd:	f3 0f 1e fb          	endbr32 
801029c1:	55                   	push   %ebp
801029c2:	89 e5                	mov    %esp,%ebp
801029c4:	53                   	push   %ebx
801029c5:	83 ec 04             	sub    $0x4,%esp
801029c8:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
801029cb:	8b 15 28 47 11 80    	mov    0x80114728,%edx
801029d1:	83 fa 1d             	cmp    $0x1d,%edx
801029d4:	7f 45                	jg     80102a1b <log_write+0x5e>
801029d6:	a1 18 47 11 80       	mov    0x80114718,%eax
801029db:	83 e8 01             	sub    $0x1,%eax
801029de:	39 c2                	cmp    %eax,%edx
801029e0:	7d 39                	jge    80102a1b <log_write+0x5e>
    panic("too big a transaction");
  if (log.outstanding < 1)
801029e2:	83 3d 1c 47 11 80 00 	cmpl   $0x0,0x8011471c
801029e9:	7e 3d                	jle    80102a28 <log_write+0x6b>
    panic("log_write outside of trans");

  acquire(&log.lock);
801029eb:	83 ec 0c             	sub    $0xc,%esp
801029ee:	68 e0 46 11 80       	push   $0x801146e0
801029f3:	e8 75 13 00 00       	call   80103d6d <acquire>
  for (i = 0; i < log.lh.n; i++) {
801029f8:	83 c4 10             	add    $0x10,%esp
801029fb:	b8 00 00 00 00       	mov    $0x0,%eax
80102a00:	8b 15 28 47 11 80    	mov    0x80114728,%edx
80102a06:	39 c2                	cmp    %eax,%edx
80102a08:	7e 2b                	jle    80102a35 <log_write+0x78>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
80102a0a:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102a0d:	39 0c 85 2c 47 11 80 	cmp    %ecx,-0x7feeb8d4(,%eax,4)
80102a14:	74 1f                	je     80102a35 <log_write+0x78>
  for (i = 0; i < log.lh.n; i++) {
80102a16:	83 c0 01             	add    $0x1,%eax
80102a19:	eb e5                	jmp    80102a00 <log_write+0x43>
    panic("too big a transaction");
80102a1b:	83 ec 0c             	sub    $0xc,%esp
80102a1e:	68 13 6b 10 80       	push   $0x80106b13
80102a23:	e8 34 d9 ff ff       	call   8010035c <panic>
    panic("log_write outside of trans");
80102a28:	83 ec 0c             	sub    $0xc,%esp
80102a2b:	68 29 6b 10 80       	push   $0x80106b29
80102a30:	e8 27 d9 ff ff       	call   8010035c <panic>
      break;
  }
  log.lh.block[i] = b->blockno;
80102a35:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102a38:	89 0c 85 2c 47 11 80 	mov    %ecx,-0x7feeb8d4(,%eax,4)
  if (i == log.lh.n)
80102a3f:	39 c2                	cmp    %eax,%edx
80102a41:	74 18                	je     80102a5b <log_write+0x9e>
    log.lh.n++;
  b->flags |= B_DIRTY; // prevent eviction
80102a43:	83 0b 04             	orl    $0x4,(%ebx)
  release(&log.lock);
80102a46:	83 ec 0c             	sub    $0xc,%esp
80102a49:	68 e0 46 11 80       	push   $0x801146e0
80102a4e:	e8 83 13 00 00       	call   80103dd6 <release>
}
80102a53:	83 c4 10             	add    $0x10,%esp
80102a56:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102a59:	c9                   	leave  
80102a5a:	c3                   	ret    
    log.lh.n++;
80102a5b:	83 c2 01             	add    $0x1,%edx
80102a5e:	89 15 28 47 11 80    	mov    %edx,0x80114728
80102a64:	eb dd                	jmp    80102a43 <log_write+0x86>

80102a66 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80102a66:	55                   	push   %ebp
80102a67:	89 e5                	mov    %esp,%ebp
80102a69:	53                   	push   %ebx
80102a6a:	83 ec 08             	sub    $0x8,%esp

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = P2V(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80102a6d:	68 8a 00 00 00       	push   $0x8a
80102a72:	68 8c a4 10 80       	push   $0x8010a48c
80102a77:	68 00 70 00 80       	push   $0x80007000
80102a7c:	e8 20 14 00 00       	call   80103ea1 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80102a81:	83 c4 10             	add    $0x10,%esp
80102a84:	bb e0 47 11 80       	mov    $0x801147e0,%ebx
80102a89:	eb 47                	jmp    80102ad2 <startothers+0x6c>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80102a8b:	e8 ff f6 ff ff       	call   8010218f <kalloc>
    *(void**)(code-4) = stack + KSTACKSIZE;
80102a90:	05 00 10 00 00       	add    $0x1000,%eax
80102a95:	a3 fc 6f 00 80       	mov    %eax,0x80006ffc
    *(void**)(code-8) = mpenter;
80102a9a:	c7 05 f8 6f 00 80 34 	movl   $0x80102b34,0x80006ff8
80102aa1:	2b 10 80 
    *(int**)(code-12) = (void *) V2P(entrypgdir);
80102aa4:	c7 05 f4 6f 00 80 00 	movl   $0x109000,0x80006ff4
80102aab:	90 10 00 

    lapicstartap(c->apicid, V2P(code));
80102aae:	83 ec 08             	sub    $0x8,%esp
80102ab1:	68 00 70 00 00       	push   $0x7000
80102ab6:	0f b6 03             	movzbl (%ebx),%eax
80102ab9:	50                   	push   %eax
80102aba:	e8 db f9 ff ff       	call   8010249a <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80102abf:	83 c4 10             	add    $0x10,%esp
80102ac2:	8b 83 a0 00 00 00    	mov    0xa0(%ebx),%eax
80102ac8:	85 c0                	test   %eax,%eax
80102aca:	74 f6                	je     80102ac2 <startothers+0x5c>
  for(c = cpus; c < cpus+ncpu; c++){
80102acc:	81 c3 b0 00 00 00    	add    $0xb0,%ebx
80102ad2:	69 05 60 4d 11 80 b0 	imul   $0xb0,0x80114d60,%eax
80102ad9:	00 00 00 
80102adc:	05 e0 47 11 80       	add    $0x801147e0,%eax
80102ae1:	39 d8                	cmp    %ebx,%eax
80102ae3:	76 0b                	jbe    80102af0 <startothers+0x8a>
    if(c == mycpu())  // We've started already.
80102ae5:	e8 b1 07 00 00       	call   8010329b <mycpu>
80102aea:	39 c3                	cmp    %eax,%ebx
80102aec:	74 de                	je     80102acc <startothers+0x66>
80102aee:	eb 9b                	jmp    80102a8b <startothers+0x25>
      ;
  }
}
80102af0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102af3:	c9                   	leave  
80102af4:	c3                   	ret    

80102af5 <mpmain>:
{
80102af5:	55                   	push   %ebp
80102af6:	89 e5                	mov    %esp,%ebp
80102af8:	53                   	push   %ebx
80102af9:	83 ec 04             	sub    $0x4,%esp
  cprintf("cpu%d: starting %d\n", cpuid(), cpuid());
80102afc:	e8 fa 07 00 00       	call   801032fb <cpuid>
80102b01:	89 c3                	mov    %eax,%ebx
80102b03:	e8 f3 07 00 00       	call   801032fb <cpuid>
80102b08:	83 ec 04             	sub    $0x4,%esp
80102b0b:	53                   	push   %ebx
80102b0c:	50                   	push   %eax
80102b0d:	68 44 6b 10 80       	push   $0x80106b44
80102b12:	e8 12 db ff ff       	call   80100629 <cprintf>
  idtinit();       // load idt register
80102b17:	e8 8c 24 00 00       	call   80104fa8 <idtinit>
  xchg(&(mycpu()->started), 1); // tell startothers() we're up
80102b1c:	e8 7a 07 00 00       	call   8010329b <mycpu>
80102b21:	89 c2                	mov    %eax,%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;

  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80102b23:	b8 01 00 00 00       	mov    $0x1,%eax
80102b28:	f0 87 82 a0 00 00 00 	lock xchg %eax,0xa0(%edx)
  scheduler();     // start running processes
80102b2f:	e8 74 0a 00 00       	call   801035a8 <scheduler>

80102b34 <mpenter>:
{
80102b34:	f3 0f 1e fb          	endbr32 
80102b38:	55                   	push   %ebp
80102b39:	89 e5                	mov    %esp,%ebp
80102b3b:	83 ec 08             	sub    $0x8,%esp
  switchkvm();
80102b3e:	e8 8c 34 00 00       	call   80105fcf <switchkvm>
  seginit();
80102b43:	e8 37 33 00 00       	call   80105e7f <seginit>
  lapicinit();
80102b48:	e8 f9 f7 ff ff       	call   80102346 <lapicinit>
  mpmain();
80102b4d:	e8 a3 ff ff ff       	call   80102af5 <mpmain>

80102b52 <main>:
{
80102b52:	f3 0f 1e fb          	endbr32 
80102b56:	8d 4c 24 04          	lea    0x4(%esp),%ecx
80102b5a:	83 e4 f0             	and    $0xfffffff0,%esp
80102b5d:	ff 71 fc             	pushl  -0x4(%ecx)
80102b60:	55                   	push   %ebp
80102b61:	89 e5                	mov    %esp,%ebp
80102b63:	51                   	push   %ecx
80102b64:	83 ec 0c             	sub    $0xc,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80102b67:	68 00 00 40 80       	push   $0x80400000
80102b6c:	68 88 55 11 80       	push   $0x80115588
80102b71:	e8 bf f5 ff ff       	call   80102135 <kinit1>
  kvmalloc();      // kernel page table
80102b76:	e8 f7 38 00 00       	call   80106472 <kvmalloc>
  mpinit();        // detect other processors
80102b7b:	e8 c1 01 00 00       	call   80102d41 <mpinit>
  lapicinit();     // interrupt controller
80102b80:	e8 c1 f7 ff ff       	call   80102346 <lapicinit>
  seginit();       // segment descriptors
80102b85:	e8 f5 32 00 00       	call   80105e7f <seginit>
  picinit();       // disable pic
80102b8a:	e8 8c 02 00 00       	call   80102e1b <picinit>
  ioapicinit();    // another interrupt controller
80102b8f:	e8 1c f4 ff ff       	call   80101fb0 <ioapicinit>
  consoleinit();   // console hardware
80102b94:	e8 5a dd ff ff       	call   801008f3 <consoleinit>
  uartinit();      // serial port
80102b99:	e8 c9 26 00 00       	call   80105267 <uartinit>
  pinit();         // process table
80102b9e:	e8 da 06 00 00       	call   8010327d <pinit>
  tvinit();        // trap vectors
80102ba3:	e8 67 23 00 00       	call   80104f0f <tvinit>
  binit();         // buffer cache
80102ba8:	e8 47 d5 ff ff       	call   801000f4 <binit>
  fileinit();      // file table
80102bad:	e8 b6 e0 ff ff       	call   80100c68 <fileinit>
  ideinit();       // disk 
80102bb2:	e8 fb f1 ff ff       	call   80101db2 <ideinit>
  startothers();   // start other processors
80102bb7:	e8 aa fe ff ff       	call   80102a66 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80102bbc:	83 c4 08             	add    $0x8,%esp
80102bbf:	68 00 00 00 8e       	push   $0x8e000000
80102bc4:	68 00 00 40 80       	push   $0x80400000
80102bc9:	e8 9d f5 ff ff       	call   8010216b <kinit2>
  userinit();      // first user process
80102bce:	e8 6f 07 00 00       	call   80103342 <userinit>
  mpmain();        // finish this processor's setup
80102bd3:	e8 1d ff ff ff       	call   80102af5 <mpmain>

80102bd8 <sum>:
int ncpu;
uchar ioapicid;

static uchar
sum(uchar *addr, int len)
{
80102bd8:	55                   	push   %ebp
80102bd9:	89 e5                	mov    %esp,%ebp
80102bdb:	56                   	push   %esi
80102bdc:	53                   	push   %ebx
80102bdd:	89 c6                	mov    %eax,%esi
  int i, sum;

  sum = 0;
80102bdf:	b8 00 00 00 00       	mov    $0x0,%eax
  for(i=0; i<len; i++)
80102be4:	b9 00 00 00 00       	mov    $0x0,%ecx
80102be9:	39 d1                	cmp    %edx,%ecx
80102beb:	7d 0b                	jge    80102bf8 <sum+0x20>
    sum += addr[i];
80102bed:	0f b6 1c 0e          	movzbl (%esi,%ecx,1),%ebx
80102bf1:	01 d8                	add    %ebx,%eax
  for(i=0; i<len; i++)
80102bf3:	83 c1 01             	add    $0x1,%ecx
80102bf6:	eb f1                	jmp    80102be9 <sum+0x11>
  return sum;
}
80102bf8:	5b                   	pop    %ebx
80102bf9:	5e                   	pop    %esi
80102bfa:	5d                   	pop    %ebp
80102bfb:	c3                   	ret    

80102bfc <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80102bfc:	55                   	push   %ebp
80102bfd:	89 e5                	mov    %esp,%ebp
80102bff:	56                   	push   %esi
80102c00:	53                   	push   %ebx
  uchar *e, *p, *addr;

  addr = P2V(a);
80102c01:	8d b0 00 00 00 80    	lea    -0x80000000(%eax),%esi
80102c07:	89 f3                	mov    %esi,%ebx
  e = addr+len;
80102c09:	01 d6                	add    %edx,%esi
  for(p = addr; p < e; p += sizeof(struct mp))
80102c0b:	eb 03                	jmp    80102c10 <mpsearch1+0x14>
80102c0d:	83 c3 10             	add    $0x10,%ebx
80102c10:	39 f3                	cmp    %esi,%ebx
80102c12:	73 29                	jae    80102c3d <mpsearch1+0x41>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80102c14:	83 ec 04             	sub    $0x4,%esp
80102c17:	6a 04                	push   $0x4
80102c19:	68 58 6b 10 80       	push   $0x80106b58
80102c1e:	53                   	push   %ebx
80102c1f:	e8 44 12 00 00       	call   80103e68 <memcmp>
80102c24:	83 c4 10             	add    $0x10,%esp
80102c27:	85 c0                	test   %eax,%eax
80102c29:	75 e2                	jne    80102c0d <mpsearch1+0x11>
80102c2b:	ba 10 00 00 00       	mov    $0x10,%edx
80102c30:	89 d8                	mov    %ebx,%eax
80102c32:	e8 a1 ff ff ff       	call   80102bd8 <sum>
80102c37:	84 c0                	test   %al,%al
80102c39:	75 d2                	jne    80102c0d <mpsearch1+0x11>
80102c3b:	eb 05                	jmp    80102c42 <mpsearch1+0x46>
      return (struct mp*)p;
  return 0;
80102c3d:	bb 00 00 00 00       	mov    $0x0,%ebx
}
80102c42:	89 d8                	mov    %ebx,%eax
80102c44:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102c47:	5b                   	pop    %ebx
80102c48:	5e                   	pop    %esi
80102c49:	5d                   	pop    %ebp
80102c4a:	c3                   	ret    

80102c4b <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80102c4b:	55                   	push   %ebp
80102c4c:	89 e5                	mov    %esp,%ebp
80102c4e:	83 ec 08             	sub    $0x8,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80102c51:	0f b6 05 0f 04 00 80 	movzbl 0x8000040f,%eax
80102c58:	c1 e0 08             	shl    $0x8,%eax
80102c5b:	0f b6 15 0e 04 00 80 	movzbl 0x8000040e,%edx
80102c62:	09 d0                	or     %edx,%eax
80102c64:	c1 e0 04             	shl    $0x4,%eax
80102c67:	74 1f                	je     80102c88 <mpsearch+0x3d>
    if((mp = mpsearch1(p, 1024)))
80102c69:	ba 00 04 00 00       	mov    $0x400,%edx
80102c6e:	e8 89 ff ff ff       	call   80102bfc <mpsearch1>
80102c73:	85 c0                	test   %eax,%eax
80102c75:	75 0f                	jne    80102c86 <mpsearch+0x3b>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
    if((mp = mpsearch1(p-1024, 1024)))
      return mp;
  }
  return mpsearch1(0xF0000, 0x10000);
80102c77:	ba 00 00 01 00       	mov    $0x10000,%edx
80102c7c:	b8 00 00 0f 00       	mov    $0xf0000,%eax
80102c81:	e8 76 ff ff ff       	call   80102bfc <mpsearch1>
}
80102c86:	c9                   	leave  
80102c87:	c3                   	ret    
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80102c88:	0f b6 05 14 04 00 80 	movzbl 0x80000414,%eax
80102c8f:	c1 e0 08             	shl    $0x8,%eax
80102c92:	0f b6 15 13 04 00 80 	movzbl 0x80000413,%edx
80102c99:	09 d0                	or     %edx,%eax
80102c9b:	c1 e0 0a             	shl    $0xa,%eax
    if((mp = mpsearch1(p-1024, 1024)))
80102c9e:	2d 00 04 00 00       	sub    $0x400,%eax
80102ca3:	ba 00 04 00 00       	mov    $0x400,%edx
80102ca8:	e8 4f ff ff ff       	call   80102bfc <mpsearch1>
80102cad:	85 c0                	test   %eax,%eax
80102caf:	75 d5                	jne    80102c86 <mpsearch+0x3b>
80102cb1:	eb c4                	jmp    80102c77 <mpsearch+0x2c>

80102cb3 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80102cb3:	55                   	push   %ebp
80102cb4:	89 e5                	mov    %esp,%ebp
80102cb6:	57                   	push   %edi
80102cb7:	56                   	push   %esi
80102cb8:	53                   	push   %ebx
80102cb9:	83 ec 1c             	sub    $0x1c,%esp
80102cbc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80102cbf:	e8 87 ff ff ff       	call   80102c4b <mpsearch>
80102cc4:	89 c3                	mov    %eax,%ebx
80102cc6:	85 c0                	test   %eax,%eax
80102cc8:	74 5a                	je     80102d24 <mpconfig+0x71>
80102cca:	8b 70 04             	mov    0x4(%eax),%esi
80102ccd:	85 f6                	test   %esi,%esi
80102ccf:	74 57                	je     80102d28 <mpconfig+0x75>
    return 0;
  conf = (struct mpconf*) P2V((uint) mp->physaddr);
80102cd1:	8d be 00 00 00 80    	lea    -0x80000000(%esi),%edi
  if(memcmp(conf, "PCMP", 4) != 0)
80102cd7:	83 ec 04             	sub    $0x4,%esp
80102cda:	6a 04                	push   $0x4
80102cdc:	68 5d 6b 10 80       	push   $0x80106b5d
80102ce1:	57                   	push   %edi
80102ce2:	e8 81 11 00 00       	call   80103e68 <memcmp>
80102ce7:	83 c4 10             	add    $0x10,%esp
80102cea:	85 c0                	test   %eax,%eax
80102cec:	75 3e                	jne    80102d2c <mpconfig+0x79>
    return 0;
  if(conf->version != 1 && conf->version != 4)
80102cee:	0f b6 86 06 00 00 80 	movzbl -0x7ffffffa(%esi),%eax
80102cf5:	3c 01                	cmp    $0x1,%al
80102cf7:	0f 95 c2             	setne  %dl
80102cfa:	3c 04                	cmp    $0x4,%al
80102cfc:	0f 95 c0             	setne  %al
80102cff:	84 c2                	test   %al,%dl
80102d01:	75 30                	jne    80102d33 <mpconfig+0x80>
    return 0;
  if(sum((uchar*)conf, conf->length) != 0)
80102d03:	0f b7 96 04 00 00 80 	movzwl -0x7ffffffc(%esi),%edx
80102d0a:	89 f8                	mov    %edi,%eax
80102d0c:	e8 c7 fe ff ff       	call   80102bd8 <sum>
80102d11:	84 c0                	test   %al,%al
80102d13:	75 25                	jne    80102d3a <mpconfig+0x87>
    return 0;
  *pmp = mp;
80102d15:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102d18:	89 18                	mov    %ebx,(%eax)
  return conf;
}
80102d1a:	89 f8                	mov    %edi,%eax
80102d1c:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102d1f:	5b                   	pop    %ebx
80102d20:	5e                   	pop    %esi
80102d21:	5f                   	pop    %edi
80102d22:	5d                   	pop    %ebp
80102d23:	c3                   	ret    
    return 0;
80102d24:	89 c7                	mov    %eax,%edi
80102d26:	eb f2                	jmp    80102d1a <mpconfig+0x67>
80102d28:	89 f7                	mov    %esi,%edi
80102d2a:	eb ee                	jmp    80102d1a <mpconfig+0x67>
    return 0;
80102d2c:	bf 00 00 00 00       	mov    $0x0,%edi
80102d31:	eb e7                	jmp    80102d1a <mpconfig+0x67>
    return 0;
80102d33:	bf 00 00 00 00       	mov    $0x0,%edi
80102d38:	eb e0                	jmp    80102d1a <mpconfig+0x67>
    return 0;
80102d3a:	bf 00 00 00 00       	mov    $0x0,%edi
80102d3f:	eb d9                	jmp    80102d1a <mpconfig+0x67>

80102d41 <mpinit>:

void
mpinit(void)
{
80102d41:	f3 0f 1e fb          	endbr32 
80102d45:	55                   	push   %ebp
80102d46:	89 e5                	mov    %esp,%ebp
80102d48:	57                   	push   %edi
80102d49:	56                   	push   %esi
80102d4a:	53                   	push   %ebx
80102d4b:	83 ec 1c             	sub    $0x1c,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  if((conf = mpconfig(&mp)) == 0)
80102d4e:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80102d51:	e8 5d ff ff ff       	call   80102cb3 <mpconfig>
80102d56:	85 c0                	test   %eax,%eax
80102d58:	74 19                	je     80102d73 <mpinit+0x32>
    panic("Expect to run on an SMP");
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
80102d5a:	8b 50 24             	mov    0x24(%eax),%edx
80102d5d:	89 15 dc 46 11 80    	mov    %edx,0x801146dc
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102d63:	8d 50 2c             	lea    0x2c(%eax),%edx
80102d66:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
80102d6a:	01 c1                	add    %eax,%ecx
  ismp = 1;
80102d6c:	bb 01 00 00 00       	mov    $0x1,%ebx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102d71:	eb 20                	jmp    80102d93 <mpinit+0x52>
    panic("Expect to run on an SMP");
80102d73:	83 ec 0c             	sub    $0xc,%esp
80102d76:	68 62 6b 10 80       	push   $0x80106b62
80102d7b:	e8 dc d5 ff ff       	call   8010035c <panic>
    switch(*p){
80102d80:	bb 00 00 00 00       	mov    $0x0,%ebx
80102d85:	eb 0c                	jmp    80102d93 <mpinit+0x52>
80102d87:	83 e8 03             	sub    $0x3,%eax
80102d8a:	3c 01                	cmp    $0x1,%al
80102d8c:	76 1a                	jbe    80102da8 <mpinit+0x67>
80102d8e:	bb 00 00 00 00       	mov    $0x0,%ebx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102d93:	39 ca                	cmp    %ecx,%edx
80102d95:	73 4d                	jae    80102de4 <mpinit+0xa3>
    switch(*p){
80102d97:	0f b6 02             	movzbl (%edx),%eax
80102d9a:	3c 02                	cmp    $0x2,%al
80102d9c:	74 38                	je     80102dd6 <mpinit+0x95>
80102d9e:	77 e7                	ja     80102d87 <mpinit+0x46>
80102da0:	84 c0                	test   %al,%al
80102da2:	74 09                	je     80102dad <mpinit+0x6c>
80102da4:	3c 01                	cmp    $0x1,%al
80102da6:	75 d8                	jne    80102d80 <mpinit+0x3f>
      p += sizeof(struct mpioapic);
      continue;
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80102da8:	83 c2 08             	add    $0x8,%edx
      continue;
80102dab:	eb e6                	jmp    80102d93 <mpinit+0x52>
      if(ncpu < NCPU) {
80102dad:	8b 35 60 4d 11 80    	mov    0x80114d60,%esi
80102db3:	83 fe 07             	cmp    $0x7,%esi
80102db6:	7f 19                	jg     80102dd1 <mpinit+0x90>
        cpus[ncpu].apicid = proc->apicid;  // apicid may differ from ncpu
80102db8:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102dbc:	69 fe b0 00 00 00    	imul   $0xb0,%esi,%edi
80102dc2:	88 87 e0 47 11 80    	mov    %al,-0x7feeb820(%edi)
        ncpu++;
80102dc8:	83 c6 01             	add    $0x1,%esi
80102dcb:	89 35 60 4d 11 80    	mov    %esi,0x80114d60
      p += sizeof(struct mpproc);
80102dd1:	83 c2 14             	add    $0x14,%edx
      continue;
80102dd4:	eb bd                	jmp    80102d93 <mpinit+0x52>
      ioapicid = ioapic->apicno;
80102dd6:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102dda:	a2 c0 47 11 80       	mov    %al,0x801147c0
      p += sizeof(struct mpioapic);
80102ddf:	83 c2 08             	add    $0x8,%edx
      continue;
80102de2:	eb af                	jmp    80102d93 <mpinit+0x52>
    default:
      ismp = 0;
      break;
    }
  }
  if(!ismp)
80102de4:	85 db                	test   %ebx,%ebx
80102de6:	74 26                	je     80102e0e <mpinit+0xcd>
    panic("Didn't find a suitable machine");

  if(mp->imcrp){
80102de8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102deb:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
80102def:	74 15                	je     80102e06 <mpinit+0xc5>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102df1:	b8 70 00 00 00       	mov    $0x70,%eax
80102df6:	ba 22 00 00 00       	mov    $0x22,%edx
80102dfb:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102dfc:	ba 23 00 00 00       	mov    $0x23,%edx
80102e01:	ec                   	in     (%dx),%al
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80102e02:	83 c8 01             	or     $0x1,%eax
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102e05:	ee                   	out    %al,(%dx)
  }
}
80102e06:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102e09:	5b                   	pop    %ebx
80102e0a:	5e                   	pop    %esi
80102e0b:	5f                   	pop    %edi
80102e0c:	5d                   	pop    %ebp
80102e0d:	c3                   	ret    
    panic("Didn't find a suitable machine");
80102e0e:	83 ec 0c             	sub    $0xc,%esp
80102e11:	68 7c 6b 10 80       	push   $0x80106b7c
80102e16:	e8 41 d5 ff ff       	call   8010035c <panic>

80102e1b <picinit>:
#define IO_PIC2         0xA0    // Slave (IRQs 8-15)

// Don't use the 8259A interrupt controllers.  Xv6 assumes SMP hardware.
void
picinit(void)
{
80102e1b:	f3 0f 1e fb          	endbr32 
80102e1f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102e24:	ba 21 00 00 00       	mov    $0x21,%edx
80102e29:	ee                   	out    %al,(%dx)
80102e2a:	ba a1 00 00 00       	mov    $0xa1,%edx
80102e2f:	ee                   	out    %al,(%dx)
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
  outb(IO_PIC2+1, 0xFF);
}
80102e30:	c3                   	ret    

80102e31 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80102e31:	f3 0f 1e fb          	endbr32 
80102e35:	55                   	push   %ebp
80102e36:	89 e5                	mov    %esp,%ebp
80102e38:	57                   	push   %edi
80102e39:	56                   	push   %esi
80102e3a:	53                   	push   %ebx
80102e3b:	83 ec 0c             	sub    $0xc,%esp
80102e3e:	8b 5d 08             	mov    0x8(%ebp),%ebx
80102e41:	8b 75 0c             	mov    0xc(%ebp),%esi
  struct pipe *p;

  p = 0;
  *f0 = *f1 = 0;
80102e44:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
80102e4a:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80102e50:	e8 31 de ff ff       	call   80100c86 <filealloc>
80102e55:	89 03                	mov    %eax,(%ebx)
80102e57:	85 c0                	test   %eax,%eax
80102e59:	0f 84 88 00 00 00    	je     80102ee7 <pipealloc+0xb6>
80102e5f:	e8 22 de ff ff       	call   80100c86 <filealloc>
80102e64:	89 06                	mov    %eax,(%esi)
80102e66:	85 c0                	test   %eax,%eax
80102e68:	74 7d                	je     80102ee7 <pipealloc+0xb6>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80102e6a:	e8 20 f3 ff ff       	call   8010218f <kalloc>
80102e6f:	89 c7                	mov    %eax,%edi
80102e71:	85 c0                	test   %eax,%eax
80102e73:	74 72                	je     80102ee7 <pipealloc+0xb6>
    goto bad;
  p->readopen = 1;
80102e75:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80102e7c:	00 00 00 
  p->writeopen = 1;
80102e7f:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80102e86:	00 00 00 
  p->nwrite = 0;
80102e89:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80102e90:	00 00 00 
  p->nread = 0;
80102e93:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80102e9a:	00 00 00 
  initlock(&p->lock, "pipe");
80102e9d:	83 ec 08             	sub    $0x8,%esp
80102ea0:	68 9b 6b 10 80       	push   $0x80106b9b
80102ea5:	50                   	push   %eax
80102ea6:	e8 72 0d 00 00       	call   80103c1d <initlock>
  (*f0)->type = FD_PIPE;
80102eab:	8b 03                	mov    (%ebx),%eax
80102ead:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80102eb3:	8b 03                	mov    (%ebx),%eax
80102eb5:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80102eb9:	8b 03                	mov    (%ebx),%eax
80102ebb:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80102ebf:	8b 03                	mov    (%ebx),%eax
80102ec1:	89 78 0c             	mov    %edi,0xc(%eax)
  (*f1)->type = FD_PIPE;
80102ec4:	8b 06                	mov    (%esi),%eax
80102ec6:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80102ecc:	8b 06                	mov    (%esi),%eax
80102ece:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80102ed2:	8b 06                	mov    (%esi),%eax
80102ed4:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80102ed8:	8b 06                	mov    (%esi),%eax
80102eda:	89 78 0c             	mov    %edi,0xc(%eax)
  return 0;
80102edd:	83 c4 10             	add    $0x10,%esp
80102ee0:	b8 00 00 00 00       	mov    $0x0,%eax
80102ee5:	eb 29                	jmp    80102f10 <pipealloc+0xdf>

//PAGEBREAK: 20
 bad:
  if(p)
    kfree((char*)p);
  if(*f0)
80102ee7:	8b 03                	mov    (%ebx),%eax
80102ee9:	85 c0                	test   %eax,%eax
80102eeb:	74 0c                	je     80102ef9 <pipealloc+0xc8>
    fileclose(*f0);
80102eed:	83 ec 0c             	sub    $0xc,%esp
80102ef0:	50                   	push   %eax
80102ef1:	e8 3e de ff ff       	call   80100d34 <fileclose>
80102ef6:	83 c4 10             	add    $0x10,%esp
  if(*f1)
80102ef9:	8b 06                	mov    (%esi),%eax
80102efb:	85 c0                	test   %eax,%eax
80102efd:	74 19                	je     80102f18 <pipealloc+0xe7>
    fileclose(*f1);
80102eff:	83 ec 0c             	sub    $0xc,%esp
80102f02:	50                   	push   %eax
80102f03:	e8 2c de ff ff       	call   80100d34 <fileclose>
80102f08:	83 c4 10             	add    $0x10,%esp
  return -1;
80102f0b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80102f10:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102f13:	5b                   	pop    %ebx
80102f14:	5e                   	pop    %esi
80102f15:	5f                   	pop    %edi
80102f16:	5d                   	pop    %ebp
80102f17:	c3                   	ret    
  return -1;
80102f18:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102f1d:	eb f1                	jmp    80102f10 <pipealloc+0xdf>

80102f1f <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80102f1f:	f3 0f 1e fb          	endbr32 
80102f23:	55                   	push   %ebp
80102f24:	89 e5                	mov    %esp,%ebp
80102f26:	53                   	push   %ebx
80102f27:	83 ec 10             	sub    $0x10,%esp
80102f2a:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&p->lock);
80102f2d:	53                   	push   %ebx
80102f2e:	e8 3a 0e 00 00       	call   80103d6d <acquire>
  if(writable){
80102f33:	83 c4 10             	add    $0x10,%esp
80102f36:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102f3a:	74 3f                	je     80102f7b <pipeclose+0x5c>
    p->writeopen = 0;
80102f3c:	c7 83 40 02 00 00 00 	movl   $0x0,0x240(%ebx)
80102f43:	00 00 00 
    wakeup(&p->nread);
80102f46:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80102f4c:	83 ec 0c             	sub    $0xc,%esp
80102f4f:	50                   	push   %eax
80102f50:	e8 17 0a 00 00       	call   8010396c <wakeup>
80102f55:	83 c4 10             	add    $0x10,%esp
  } else {
    p->readopen = 0;
    wakeup(&p->nwrite);
  }
  if(p->readopen == 0 && p->writeopen == 0){
80102f58:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
80102f5f:	75 09                	jne    80102f6a <pipeclose+0x4b>
80102f61:	83 bb 40 02 00 00 00 	cmpl   $0x0,0x240(%ebx)
80102f68:	74 2f                	je     80102f99 <pipeclose+0x7a>
    release(&p->lock);
    kfree((char*)p);
  } else
    release(&p->lock);
80102f6a:	83 ec 0c             	sub    $0xc,%esp
80102f6d:	53                   	push   %ebx
80102f6e:	e8 63 0e 00 00       	call   80103dd6 <release>
80102f73:	83 c4 10             	add    $0x10,%esp
}
80102f76:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102f79:	c9                   	leave  
80102f7a:	c3                   	ret    
    p->readopen = 0;
80102f7b:	c7 83 3c 02 00 00 00 	movl   $0x0,0x23c(%ebx)
80102f82:	00 00 00 
    wakeup(&p->nwrite);
80102f85:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80102f8b:	83 ec 0c             	sub    $0xc,%esp
80102f8e:	50                   	push   %eax
80102f8f:	e8 d8 09 00 00       	call   8010396c <wakeup>
80102f94:	83 c4 10             	add    $0x10,%esp
80102f97:	eb bf                	jmp    80102f58 <pipeclose+0x39>
    release(&p->lock);
80102f99:	83 ec 0c             	sub    $0xc,%esp
80102f9c:	53                   	push   %ebx
80102f9d:	e8 34 0e 00 00       	call   80103dd6 <release>
    kfree((char*)p);
80102fa2:	89 1c 24             	mov    %ebx,(%esp)
80102fa5:	e8 be f0 ff ff       	call   80102068 <kfree>
80102faa:	83 c4 10             	add    $0x10,%esp
80102fad:	eb c7                	jmp    80102f76 <pipeclose+0x57>

80102faf <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
80102faf:	f3 0f 1e fb          	endbr32 
80102fb3:	55                   	push   %ebp
80102fb4:	89 e5                	mov    %esp,%ebp
80102fb6:	57                   	push   %edi
80102fb7:	56                   	push   %esi
80102fb8:	53                   	push   %ebx
80102fb9:	83 ec 18             	sub    $0x18,%esp
80102fbc:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
80102fbf:	89 de                	mov    %ebx,%esi
80102fc1:	53                   	push   %ebx
80102fc2:	e8 a6 0d 00 00       	call   80103d6d <acquire>
  for(i = 0; i < n; i++){
80102fc7:	83 c4 10             	add    $0x10,%esp
80102fca:	bf 00 00 00 00       	mov    $0x0,%edi
80102fcf:	3b 7d 10             	cmp    0x10(%ebp),%edi
80102fd2:	7c 41                	jl     80103015 <pipewrite+0x66>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80102fd4:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80102fda:	83 ec 0c             	sub    $0xc,%esp
80102fdd:	50                   	push   %eax
80102fde:	e8 89 09 00 00       	call   8010396c <wakeup>
  release(&p->lock);
80102fe3:	89 1c 24             	mov    %ebx,(%esp)
80102fe6:	e8 eb 0d 00 00       	call   80103dd6 <release>
  return n;
80102feb:	83 c4 10             	add    $0x10,%esp
80102fee:	8b 45 10             	mov    0x10(%ebp),%eax
80102ff1:	eb 5c                	jmp    8010304f <pipewrite+0xa0>
      wakeup(&p->nread);
80102ff3:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80102ff9:	83 ec 0c             	sub    $0xc,%esp
80102ffc:	50                   	push   %eax
80102ffd:	e8 6a 09 00 00       	call   8010396c <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80103002:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80103008:	83 c4 08             	add    $0x8,%esp
8010300b:	56                   	push   %esi
8010300c:	50                   	push   %eax
8010300d:	e8 ee 07 00 00       	call   80103800 <sleep>
80103012:	83 c4 10             	add    $0x10,%esp
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80103015:	8b 93 38 02 00 00    	mov    0x238(%ebx),%edx
8010301b:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
80103021:	05 00 02 00 00       	add    $0x200,%eax
80103026:	39 c2                	cmp    %eax,%edx
80103028:	75 2d                	jne    80103057 <pipewrite+0xa8>
      if(p->readopen == 0 || myproc()->killed){
8010302a:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
80103031:	74 0b                	je     8010303e <pipewrite+0x8f>
80103033:	e8 e2 02 00 00       	call   8010331a <myproc>
80103038:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
8010303c:	74 b5                	je     80102ff3 <pipewrite+0x44>
        release(&p->lock);
8010303e:	83 ec 0c             	sub    $0xc,%esp
80103041:	53                   	push   %ebx
80103042:	e8 8f 0d 00 00       	call   80103dd6 <release>
        return -1;
80103047:	83 c4 10             	add    $0x10,%esp
8010304a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010304f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103052:	5b                   	pop    %ebx
80103053:	5e                   	pop    %esi
80103054:	5f                   	pop    %edi
80103055:	5d                   	pop    %ebp
80103056:	c3                   	ret    
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80103057:	8d 42 01             	lea    0x1(%edx),%eax
8010305a:	89 83 38 02 00 00    	mov    %eax,0x238(%ebx)
80103060:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80103066:	8b 45 0c             	mov    0xc(%ebp),%eax
80103069:	0f b6 04 38          	movzbl (%eax,%edi,1),%eax
8010306d:	88 44 13 34          	mov    %al,0x34(%ebx,%edx,1)
  for(i = 0; i < n; i++){
80103071:	83 c7 01             	add    $0x1,%edi
80103074:	e9 56 ff ff ff       	jmp    80102fcf <pipewrite+0x20>

80103079 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80103079:	f3 0f 1e fb          	endbr32 
8010307d:	55                   	push   %ebp
8010307e:	89 e5                	mov    %esp,%ebp
80103080:	57                   	push   %edi
80103081:	56                   	push   %esi
80103082:	53                   	push   %ebx
80103083:	83 ec 18             	sub    $0x18,%esp
80103086:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
80103089:	89 df                	mov    %ebx,%edi
8010308b:	53                   	push   %ebx
8010308c:	e8 dc 0c 00 00       	call   80103d6d <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80103091:	83 c4 10             	add    $0x10,%esp
80103094:	eb 13                	jmp    801030a9 <piperead+0x30>
    if(myproc()->killed){
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
80103096:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
8010309c:	83 ec 08             	sub    $0x8,%esp
8010309f:	57                   	push   %edi
801030a0:	50                   	push   %eax
801030a1:	e8 5a 07 00 00       	call   80103800 <sleep>
801030a6:	83 c4 10             	add    $0x10,%esp
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
801030a9:	8b 83 38 02 00 00    	mov    0x238(%ebx),%eax
801030af:	39 83 34 02 00 00    	cmp    %eax,0x234(%ebx)
801030b5:	75 28                	jne    801030df <piperead+0x66>
801030b7:	8b b3 40 02 00 00    	mov    0x240(%ebx),%esi
801030bd:	85 f6                	test   %esi,%esi
801030bf:	74 23                	je     801030e4 <piperead+0x6b>
    if(myproc()->killed){
801030c1:	e8 54 02 00 00       	call   8010331a <myproc>
801030c6:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801030ca:	74 ca                	je     80103096 <piperead+0x1d>
      release(&p->lock);
801030cc:	83 ec 0c             	sub    $0xc,%esp
801030cf:	53                   	push   %ebx
801030d0:	e8 01 0d 00 00       	call   80103dd6 <release>
      return -1;
801030d5:	83 c4 10             	add    $0x10,%esp
801030d8:	be ff ff ff ff       	mov    $0xffffffff,%esi
801030dd:	eb 50                	jmp    8010312f <piperead+0xb6>
801030df:	be 00 00 00 00       	mov    $0x0,%esi
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801030e4:	3b 75 10             	cmp    0x10(%ebp),%esi
801030e7:	7d 2c                	jge    80103115 <piperead+0x9c>
    if(p->nread == p->nwrite)
801030e9:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
801030ef:	3b 83 38 02 00 00    	cmp    0x238(%ebx),%eax
801030f5:	74 1e                	je     80103115 <piperead+0x9c>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
801030f7:	8d 50 01             	lea    0x1(%eax),%edx
801030fa:	89 93 34 02 00 00    	mov    %edx,0x234(%ebx)
80103100:	25 ff 01 00 00       	and    $0x1ff,%eax
80103105:	0f b6 44 03 34       	movzbl 0x34(%ebx,%eax,1),%eax
8010310a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
8010310d:	88 04 31             	mov    %al,(%ecx,%esi,1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80103110:	83 c6 01             	add    $0x1,%esi
80103113:	eb cf                	jmp    801030e4 <piperead+0x6b>
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80103115:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
8010311b:	83 ec 0c             	sub    $0xc,%esp
8010311e:	50                   	push   %eax
8010311f:	e8 48 08 00 00       	call   8010396c <wakeup>
  release(&p->lock);
80103124:	89 1c 24             	mov    %ebx,(%esp)
80103127:	e8 aa 0c 00 00       	call   80103dd6 <release>
  return i;
8010312c:	83 c4 10             	add    $0x10,%esp
}
8010312f:	89 f0                	mov    %esi,%eax
80103131:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103134:	5b                   	pop    %ebx
80103135:	5e                   	pop    %esi
80103136:	5f                   	pop    %edi
80103137:	5d                   	pop    %ebp
80103138:	c3                   	ret    

80103139 <wakeup1>:
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103139:	ba 14 a6 10 80       	mov    $0x8010a614,%edx
8010313e:	eb 0a                	jmp    8010314a <wakeup1+0x11>
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
80103140:	c7 42 0c 03 00 00 00 	movl   $0x3,0xc(%edx)
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103147:	83 ea 80             	sub    $0xffffff80,%edx
8010314a:	81 fa 14 c6 10 80    	cmp    $0x8010c614,%edx
80103150:	73 0d                	jae    8010315f <wakeup1+0x26>
    if(p->state == SLEEPING && p->chan == chan)
80103152:	83 7a 0c 02          	cmpl   $0x2,0xc(%edx)
80103156:	75 ef                	jne    80103147 <wakeup1+0xe>
80103158:	39 42 20             	cmp    %eax,0x20(%edx)
8010315b:	75 ea                	jne    80103147 <wakeup1+0xe>
8010315d:	eb e1                	jmp    80103140 <wakeup1+0x7>
}
8010315f:	c3                   	ret    

80103160 <allocproc>:
{
80103160:	55                   	push   %ebp
80103161:	89 e5                	mov    %esp,%ebp
80103163:	53                   	push   %ebx
80103164:	83 ec 10             	sub    $0x10,%esp
  acquire(&ptable.lock);
80103167:	68 e0 a5 10 80       	push   $0x8010a5e0
8010316c:	e8 fc 0b 00 00       	call   80103d6d <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103171:	83 c4 10             	add    $0x10,%esp
80103174:	bb 14 a6 10 80       	mov    $0x8010a614,%ebx
80103179:	81 fb 14 c6 10 80    	cmp    $0x8010c614,%ebx
8010317f:	73 0b                	jae    8010318c <allocproc+0x2c>
    if(p->state == UNUSED) {
80103181:	83 7b 0c 00          	cmpl   $0x0,0xc(%ebx)
80103185:	74 0c                	je     80103193 <allocproc+0x33>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103187:	83 eb 80             	sub    $0xffffff80,%ebx
8010318a:	eb ed                	jmp    80103179 <allocproc+0x19>
  int found = 0;
8010318c:	b8 00 00 00 00       	mov    $0x0,%eax
80103191:	eb 05                	jmp    80103198 <allocproc+0x38>
      found = 1;
80103193:	b8 01 00 00 00       	mov    $0x1,%eax
  if (!found) {
80103198:	85 c0                	test   %eax,%eax
8010319a:	74 78                	je     80103214 <allocproc+0xb4>
  p->state = EMBRYO;
8010319c:	c7 43 0c 01 00 00 00 	movl   $0x1,0xc(%ebx)
  p->pid = nextpid++;
801031a3:	a1 04 a0 10 80       	mov    0x8010a004,%eax
801031a8:	8d 50 01             	lea    0x1(%eax),%edx
801031ab:	89 15 04 a0 10 80    	mov    %edx,0x8010a004
801031b1:	89 43 10             	mov    %eax,0x10(%ebx)
  release(&ptable.lock);
801031b4:	83 ec 0c             	sub    $0xc,%esp
801031b7:	68 e0 a5 10 80       	push   $0x8010a5e0
801031bc:	e8 15 0c 00 00       	call   80103dd6 <release>
  if((p->kstack = kalloc()) == 0){
801031c1:	e8 c9 ef ff ff       	call   8010218f <kalloc>
801031c6:	89 43 08             	mov    %eax,0x8(%ebx)
801031c9:	83 c4 10             	add    $0x10,%esp
801031cc:	85 c0                	test   %eax,%eax
801031ce:	74 5b                	je     8010322b <allocproc+0xcb>
  sp -= sizeof *p->tf;
801031d0:	8d 90 b4 0f 00 00    	lea    0xfb4(%eax),%edx
  p->tf = (struct trapframe*)sp;
801031d6:	89 53 18             	mov    %edx,0x18(%ebx)
  *(uint*)sp = (uint)trapret;
801031d9:	c7 80 b0 0f 00 00 04 	movl   $0x80104f04,0xfb0(%eax)
801031e0:	4f 10 80 
  sp -= sizeof *p->context;
801031e3:	05 9c 0f 00 00       	add    $0xf9c,%eax
  p->context = (struct context*)sp;
801031e8:	89 43 1c             	mov    %eax,0x1c(%ebx)
  memset(p->context, 0, sizeof *p->context);
801031eb:	83 ec 04             	sub    $0x4,%esp
801031ee:	6a 14                	push   $0x14
801031f0:	6a 00                	push   $0x0
801031f2:	50                   	push   %eax
801031f3:	e8 29 0c 00 00       	call   80103e21 <memset>
  p->context->eip = (uint)forkret;
801031f8:	8b 43 1c             	mov    0x1c(%ebx),%eax
801031fb:	c7 40 10 36 32 10 80 	movl   $0x80103236,0x10(%eax)
    p->start_ticks = ticks;
80103202:	a1 80 55 11 80       	mov    0x80115580,%eax
80103207:	89 43 7c             	mov    %eax,0x7c(%ebx)
  return p;
8010320a:	83 c4 10             	add    $0x10,%esp
}
8010320d:	89 d8                	mov    %ebx,%eax
8010320f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103212:	c9                   	leave  
80103213:	c3                   	ret    
    release(&ptable.lock);
80103214:	83 ec 0c             	sub    $0xc,%esp
80103217:	68 e0 a5 10 80       	push   $0x8010a5e0
8010321c:	e8 b5 0b 00 00       	call   80103dd6 <release>
    return 0;
80103221:	83 c4 10             	add    $0x10,%esp
80103224:	bb 00 00 00 00       	mov    $0x0,%ebx
80103229:	eb e2                	jmp    8010320d <allocproc+0xad>
    p->state = UNUSED;
8010322b:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return 0;
80103232:	89 c3                	mov    %eax,%ebx
80103234:	eb d7                	jmp    8010320d <allocproc+0xad>

80103236 <forkret>:
{
80103236:	f3 0f 1e fb          	endbr32 
8010323a:	55                   	push   %ebp
8010323b:	89 e5                	mov    %esp,%ebp
8010323d:	83 ec 14             	sub    $0x14,%esp
  release(&ptable.lock);
80103240:	68 e0 a5 10 80       	push   $0x8010a5e0
80103245:	e8 8c 0b 00 00       	call   80103dd6 <release>
  if (first) {
8010324a:	83 c4 10             	add    $0x10,%esp
8010324d:	83 3d 00 a0 10 80 00 	cmpl   $0x0,0x8010a000
80103254:	75 02                	jne    80103258 <forkret+0x22>
}
80103256:	c9                   	leave  
80103257:	c3                   	ret    
    first = 0;
80103258:	c7 05 00 a0 10 80 00 	movl   $0x0,0x8010a000
8010325f:	00 00 00 
    iinit(ROOTDEV);
80103262:	83 ec 0c             	sub    $0xc,%esp
80103265:	6a 01                	push   $0x1
80103267:	e8 f6 e0 ff ff       	call   80101362 <iinit>
    initlog(ROOTDEV);
8010326c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103273:	e8 c7 f5 ff ff       	call   8010283f <initlog>
80103278:	83 c4 10             	add    $0x10,%esp
}
8010327b:	eb d9                	jmp    80103256 <forkret+0x20>

8010327d <pinit>:
{
8010327d:	f3 0f 1e fb          	endbr32 
80103281:	55                   	push   %ebp
80103282:	89 e5                	mov    %esp,%ebp
80103284:	83 ec 10             	sub    $0x10,%esp
  initlock(&ptable.lock, "ptable");
80103287:	68 a0 6b 10 80       	push   $0x80106ba0
8010328c:	68 e0 a5 10 80       	push   $0x8010a5e0
80103291:	e8 87 09 00 00       	call   80103c1d <initlock>
}
80103296:	83 c4 10             	add    $0x10,%esp
80103299:	c9                   	leave  
8010329a:	c3                   	ret    

8010329b <mycpu>:
{
8010329b:	f3 0f 1e fb          	endbr32 
8010329f:	55                   	push   %ebp
801032a0:	89 e5                	mov    %esp,%ebp
801032a2:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801032a5:	9c                   	pushf  
801032a6:	58                   	pop    %eax
  if(readeflags()&FL_IF)
801032a7:	f6 c4 02             	test   $0x2,%ah
801032aa:	75 28                	jne    801032d4 <mycpu+0x39>
  apicid = lapicid();
801032ac:	e8 a5 f1 ff ff       	call   80102456 <lapicid>
  for (i = 0; i < ncpu; ++i) {
801032b1:	ba 00 00 00 00       	mov    $0x0,%edx
801032b6:	39 15 60 4d 11 80    	cmp    %edx,0x80114d60
801032bc:	7e 30                	jle    801032ee <mycpu+0x53>
    if (cpus[i].apicid == apicid) {
801032be:	69 ca b0 00 00 00    	imul   $0xb0,%edx,%ecx
801032c4:	0f b6 89 e0 47 11 80 	movzbl -0x7feeb820(%ecx),%ecx
801032cb:	39 c1                	cmp    %eax,%ecx
801032cd:	74 12                	je     801032e1 <mycpu+0x46>
  for (i = 0; i < ncpu; ++i) {
801032cf:	83 c2 01             	add    $0x1,%edx
801032d2:	eb e2                	jmp    801032b6 <mycpu+0x1b>
    panic("mycpu called with interrupts enabled\n");
801032d4:	83 ec 0c             	sub    $0xc,%esp
801032d7:	68 80 6c 10 80       	push   $0x80106c80
801032dc:	e8 7b d0 ff ff       	call   8010035c <panic>
      return &cpus[i];
801032e1:	69 c2 b0 00 00 00    	imul   $0xb0,%edx,%eax
801032e7:	05 e0 47 11 80       	add    $0x801147e0,%eax
}
801032ec:	c9                   	leave  
801032ed:	c3                   	ret    
  panic("unknown apicid\n");
801032ee:	83 ec 0c             	sub    $0xc,%esp
801032f1:	68 a7 6b 10 80       	push   $0x80106ba7
801032f6:	e8 61 d0 ff ff       	call   8010035c <panic>

801032fb <cpuid>:
cpuid() {
801032fb:	f3 0f 1e fb          	endbr32 
801032ff:	55                   	push   %ebp
80103300:	89 e5                	mov    %esp,%ebp
80103302:	83 ec 08             	sub    $0x8,%esp
  return mycpu()-cpus;
80103305:	e8 91 ff ff ff       	call   8010329b <mycpu>
8010330a:	2d e0 47 11 80       	sub    $0x801147e0,%eax
8010330f:	c1 f8 04             	sar    $0x4,%eax
80103312:	69 c0 a3 8b 2e ba    	imul   $0xba2e8ba3,%eax,%eax
}
80103318:	c9                   	leave  
80103319:	c3                   	ret    

8010331a <myproc>:
myproc(void) {
8010331a:	f3 0f 1e fb          	endbr32 
8010331e:	55                   	push   %ebp
8010331f:	89 e5                	mov    %esp,%ebp
80103321:	53                   	push   %ebx
80103322:	83 ec 04             	sub    $0x4,%esp
  pushcli();
80103325:	e8 5a 09 00 00       	call   80103c84 <pushcli>
  c = mycpu();
8010332a:	e8 6c ff ff ff       	call   8010329b <mycpu>
  p = c->proc;
8010332f:	8b 98 ac 00 00 00    	mov    0xac(%eax),%ebx
  popcli();
80103335:	e8 8b 09 00 00       	call   80103cc5 <popcli>
}
8010333a:	89 d8                	mov    %ebx,%eax
8010333c:	83 c4 04             	add    $0x4,%esp
8010333f:	5b                   	pop    %ebx
80103340:	5d                   	pop    %ebp
80103341:	c3                   	ret    

80103342 <userinit>:
{
80103342:	f3 0f 1e fb          	endbr32 
80103346:	55                   	push   %ebp
80103347:	89 e5                	mov    %esp,%ebp
80103349:	53                   	push   %ebx
8010334a:	83 ec 04             	sub    $0x4,%esp
  p = allocproc();
8010334d:	e8 0e fe ff ff       	call   80103160 <allocproc>
80103352:	89 c3                	mov    %eax,%ebx
  initproc = p;
80103354:	a3 c0 a5 10 80       	mov    %eax,0x8010a5c0
  if((p->pgdir = setupkvm()) == 0)
80103359:	e8 a2 30 00 00       	call   80106400 <setupkvm>
8010335e:	89 43 04             	mov    %eax,0x4(%ebx)
80103361:	85 c0                	test   %eax,%eax
80103363:	0f 84 b8 00 00 00    	je     80103421 <userinit+0xdf>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80103369:	83 ec 04             	sub    $0x4,%esp
8010336c:	68 2c 00 00 00       	push   $0x2c
80103371:	68 60 a4 10 80       	push   $0x8010a460
80103376:	50                   	push   %eax
80103377:	e8 81 2d 00 00       	call   801060fd <inituvm>
  p->sz = PGSIZE;
8010337c:	c7 03 00 10 00 00    	movl   $0x1000,(%ebx)
  memset(p->tf, 0, sizeof(*p->tf));
80103382:	8b 43 18             	mov    0x18(%ebx),%eax
80103385:	83 c4 0c             	add    $0xc,%esp
80103388:	6a 4c                	push   $0x4c
8010338a:	6a 00                	push   $0x0
8010338c:	50                   	push   %eax
8010338d:	e8 8f 0a 00 00       	call   80103e21 <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
80103392:	8b 43 18             	mov    0x18(%ebx),%eax
80103395:	66 c7 40 3c 1b 00    	movw   $0x1b,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
8010339b:	8b 43 18             	mov    0x18(%ebx),%eax
8010339e:	66 c7 40 2c 23 00    	movw   $0x23,0x2c(%eax)
  p->tf->es = p->tf->ds;
801033a4:	8b 43 18             	mov    0x18(%ebx),%eax
801033a7:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
801033ab:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
801033af:	8b 43 18             	mov    0x18(%ebx),%eax
801033b2:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
801033b6:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
801033ba:	8b 43 18             	mov    0x18(%ebx),%eax
801033bd:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
801033c4:	8b 43 18             	mov    0x18(%ebx),%eax
801033c7:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
801033ce:	8b 43 18             	mov    0x18(%ebx),%eax
801033d1:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)
  safestrcpy(p->name, "initcode", sizeof(p->name));
801033d8:	8d 43 6c             	lea    0x6c(%ebx),%eax
801033db:	83 c4 0c             	add    $0xc,%esp
801033de:	6a 10                	push   $0x10
801033e0:	68 d0 6b 10 80       	push   $0x80106bd0
801033e5:	50                   	push   %eax
801033e6:	e8 b6 0b 00 00       	call   80103fa1 <safestrcpy>
  p->cwd = namei("/");
801033eb:	c7 04 24 d9 6b 10 80 	movl   $0x80106bd9,(%esp)
801033f2:	e8 95 e8 ff ff       	call   80101c8c <namei>
801033f7:	89 43 68             	mov    %eax,0x68(%ebx)
  acquire(&ptable.lock);
801033fa:	c7 04 24 e0 a5 10 80 	movl   $0x8010a5e0,(%esp)
80103401:	e8 67 09 00 00       	call   80103d6d <acquire>
  p->state = RUNNABLE;
80103406:	c7 43 0c 03 00 00 00 	movl   $0x3,0xc(%ebx)
  release(&ptable.lock);
8010340d:	c7 04 24 e0 a5 10 80 	movl   $0x8010a5e0,(%esp)
80103414:	e8 bd 09 00 00       	call   80103dd6 <release>
}
80103419:	83 c4 10             	add    $0x10,%esp
8010341c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010341f:	c9                   	leave  
80103420:	c3                   	ret    
    panic("userinit: out of memory?");
80103421:	83 ec 0c             	sub    $0xc,%esp
80103424:	68 b7 6b 10 80       	push   $0x80106bb7
80103429:	e8 2e cf ff ff       	call   8010035c <panic>

8010342e <growproc>:
{
8010342e:	f3 0f 1e fb          	endbr32 
80103432:	55                   	push   %ebp
80103433:	89 e5                	mov    %esp,%ebp
80103435:	56                   	push   %esi
80103436:	53                   	push   %ebx
80103437:	8b 75 08             	mov    0x8(%ebp),%esi
  struct proc *curproc = myproc();
8010343a:	e8 db fe ff ff       	call   8010331a <myproc>
8010343f:	89 c3                	mov    %eax,%ebx
  sz = curproc->sz;
80103441:	8b 00                	mov    (%eax),%eax
  if(n > 0){
80103443:	85 f6                	test   %esi,%esi
80103445:	7f 1c                	jg     80103463 <growproc+0x35>
  } else if(n < 0){
80103447:	78 37                	js     80103480 <growproc+0x52>
  curproc->sz = sz;
80103449:	89 03                	mov    %eax,(%ebx)
  switchuvm(curproc);
8010344b:	83 ec 0c             	sub    $0xc,%esp
8010344e:	53                   	push   %ebx
8010344f:	e8 8d 2b 00 00       	call   80105fe1 <switchuvm>
  return 0;
80103454:	83 c4 10             	add    $0x10,%esp
80103457:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010345c:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010345f:	5b                   	pop    %ebx
80103460:	5e                   	pop    %esi
80103461:	5d                   	pop    %ebp
80103462:	c3                   	ret    
    if((sz = allocuvm(curproc->pgdir, sz, sz + n)) == 0)
80103463:	83 ec 04             	sub    $0x4,%esp
80103466:	01 c6                	add    %eax,%esi
80103468:	56                   	push   %esi
80103469:	50                   	push   %eax
8010346a:	ff 73 04             	pushl  0x4(%ebx)
8010346d:	e8 2d 2e 00 00       	call   8010629f <allocuvm>
80103472:	83 c4 10             	add    $0x10,%esp
80103475:	85 c0                	test   %eax,%eax
80103477:	75 d0                	jne    80103449 <growproc+0x1b>
      return -1;
80103479:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010347e:	eb dc                	jmp    8010345c <growproc+0x2e>
    if((sz = deallocuvm(curproc->pgdir, sz, sz + n)) == 0)
80103480:	83 ec 04             	sub    $0x4,%esp
80103483:	01 c6                	add    %eax,%esi
80103485:	56                   	push   %esi
80103486:	50                   	push   %eax
80103487:	ff 73 04             	pushl  0x4(%ebx)
8010348a:	e8 7a 2d 00 00       	call   80106209 <deallocuvm>
8010348f:	83 c4 10             	add    $0x10,%esp
80103492:	85 c0                	test   %eax,%eax
80103494:	75 b3                	jne    80103449 <growproc+0x1b>
      return -1;
80103496:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010349b:	eb bf                	jmp    8010345c <growproc+0x2e>

8010349d <fork>:
{
8010349d:	f3 0f 1e fb          	endbr32 
801034a1:	55                   	push   %ebp
801034a2:	89 e5                	mov    %esp,%ebp
801034a4:	57                   	push   %edi
801034a5:	56                   	push   %esi
801034a6:	53                   	push   %ebx
801034a7:	83 ec 1c             	sub    $0x1c,%esp
  struct proc *curproc = myproc();
801034aa:	e8 6b fe ff ff       	call   8010331a <myproc>
801034af:	89 c3                	mov    %eax,%ebx
  if((np = allocproc()) == 0){
801034b1:	e8 aa fc ff ff       	call   80103160 <allocproc>
801034b6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801034b9:	85 c0                	test   %eax,%eax
801034bb:	0f 84 e0 00 00 00    	je     801035a1 <fork+0x104>
801034c1:	89 c7                	mov    %eax,%edi
  if((np->pgdir = copyuvm(curproc->pgdir, curproc->sz)) == 0){
801034c3:	83 ec 08             	sub    $0x8,%esp
801034c6:	ff 33                	pushl  (%ebx)
801034c8:	ff 73 04             	pushl  0x4(%ebx)
801034cb:	e8 ed 2f 00 00       	call   801064bd <copyuvm>
801034d0:	89 47 04             	mov    %eax,0x4(%edi)
801034d3:	83 c4 10             	add    $0x10,%esp
801034d6:	85 c0                	test   %eax,%eax
801034d8:	74 2a                	je     80103504 <fork+0x67>
  np->sz = curproc->sz;
801034da:	8b 03                	mov    (%ebx),%eax
801034dc:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801034df:	89 01                	mov    %eax,(%ecx)
  np->parent = curproc;
801034e1:	89 c8                	mov    %ecx,%eax
801034e3:	89 59 14             	mov    %ebx,0x14(%ecx)
  *np->tf = *curproc->tf;
801034e6:	8b 73 18             	mov    0x18(%ebx),%esi
801034e9:	8b 79 18             	mov    0x18(%ecx),%edi
801034ec:	b9 13 00 00 00       	mov    $0x13,%ecx
801034f1:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  np->tf->eax = 0;
801034f3:	8b 40 18             	mov    0x18(%eax),%eax
801034f6:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
  for(i = 0; i < NOFILE; i++)
801034fd:	be 00 00 00 00       	mov    $0x0,%esi
80103502:	eb 3c                	jmp    80103540 <fork+0xa3>
    kfree(np->kstack);
80103504:	83 ec 0c             	sub    $0xc,%esp
80103507:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
8010350a:	ff 73 08             	pushl  0x8(%ebx)
8010350d:	e8 56 eb ff ff       	call   80102068 <kfree>
    np->kstack = 0;
80103512:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
    np->state = UNUSED;
80103519:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return -1;
80103520:	83 c4 10             	add    $0x10,%esp
80103523:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103528:	eb 6f                	jmp    80103599 <fork+0xfc>
      np->ofile[i] = filedup(curproc->ofile[i]);
8010352a:	83 ec 0c             	sub    $0xc,%esp
8010352d:	50                   	push   %eax
8010352e:	e8 b8 d7 ff ff       	call   80100ceb <filedup>
80103533:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80103536:	89 44 b2 28          	mov    %eax,0x28(%edx,%esi,4)
8010353a:	83 c4 10             	add    $0x10,%esp
  for(i = 0; i < NOFILE; i++)
8010353d:	83 c6 01             	add    $0x1,%esi
80103540:	83 fe 0f             	cmp    $0xf,%esi
80103543:	7f 0a                	jg     8010354f <fork+0xb2>
    if(curproc->ofile[i])
80103545:	8b 44 b3 28          	mov    0x28(%ebx,%esi,4),%eax
80103549:	85 c0                	test   %eax,%eax
8010354b:	75 dd                	jne    8010352a <fork+0x8d>
8010354d:	eb ee                	jmp    8010353d <fork+0xa0>
  np->cwd = idup(curproc->cwd);
8010354f:	83 ec 0c             	sub    $0xc,%esp
80103552:	ff 73 68             	pushl  0x68(%ebx)
80103555:	e8 79 e0 ff ff       	call   801015d3 <idup>
8010355a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
8010355d:	89 47 68             	mov    %eax,0x68(%edi)
  safestrcpy(np->name, curproc->name, sizeof(curproc->name));
80103560:	83 c3 6c             	add    $0x6c,%ebx
80103563:	8d 47 6c             	lea    0x6c(%edi),%eax
80103566:	83 c4 0c             	add    $0xc,%esp
80103569:	6a 10                	push   $0x10
8010356b:	53                   	push   %ebx
8010356c:	50                   	push   %eax
8010356d:	e8 2f 0a 00 00       	call   80103fa1 <safestrcpy>
  pid = np->pid;
80103572:	8b 5f 10             	mov    0x10(%edi),%ebx
  acquire(&ptable.lock);
80103575:	c7 04 24 e0 a5 10 80 	movl   $0x8010a5e0,(%esp)
8010357c:	e8 ec 07 00 00       	call   80103d6d <acquire>
  np->state = RUNNABLE;
80103581:	c7 47 0c 03 00 00 00 	movl   $0x3,0xc(%edi)
  release(&ptable.lock);
80103588:	c7 04 24 e0 a5 10 80 	movl   $0x8010a5e0,(%esp)
8010358f:	e8 42 08 00 00       	call   80103dd6 <release>
  return pid;
80103594:	89 d8                	mov    %ebx,%eax
80103596:	83 c4 10             	add    $0x10,%esp
}
80103599:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010359c:	5b                   	pop    %ebx
8010359d:	5e                   	pop    %esi
8010359e:	5f                   	pop    %edi
8010359f:	5d                   	pop    %ebp
801035a0:	c3                   	ret    
    return -1;
801035a1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801035a6:	eb f1                	jmp    80103599 <fork+0xfc>

801035a8 <scheduler>:
{
801035a8:	f3 0f 1e fb          	endbr32 
801035ac:	55                   	push   %ebp
801035ad:	89 e5                	mov    %esp,%ebp
801035af:	57                   	push   %edi
801035b0:	56                   	push   %esi
801035b1:	53                   	push   %ebx
801035b2:	83 ec 0c             	sub    $0xc,%esp
  struct cpu *c = mycpu();
801035b5:	e8 e1 fc ff ff       	call   8010329b <mycpu>
801035ba:	89 c6                	mov    %eax,%esi
  c->proc = 0;
801035bc:	c7 80 ac 00 00 00 00 	movl   $0x0,0xac(%eax)
801035c3:	00 00 00 
801035c6:	eb 65                	jmp    8010362d <scheduler+0x85>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801035c8:	83 eb 80             	sub    $0xffffff80,%ebx
801035cb:	81 fb 14 c6 10 80    	cmp    $0x8010c614,%ebx
801035d1:	73 44                	jae    80103617 <scheduler+0x6f>
      if(p->state != RUNNABLE)
801035d3:	83 7b 0c 03          	cmpl   $0x3,0xc(%ebx)
801035d7:	75 ef                	jne    801035c8 <scheduler+0x20>
      c->proc = p;
801035d9:	89 9e ac 00 00 00    	mov    %ebx,0xac(%esi)
      switchuvm(p);
801035df:	83 ec 0c             	sub    $0xc,%esp
801035e2:	53                   	push   %ebx
801035e3:	e8 f9 29 00 00       	call   80105fe1 <switchuvm>
      p->state = RUNNING;
801035e8:	c7 43 0c 04 00 00 00 	movl   $0x4,0xc(%ebx)
      swtch(&(c->scheduler), p->context);
801035ef:	83 c4 08             	add    $0x8,%esp
801035f2:	ff 73 1c             	pushl  0x1c(%ebx)
801035f5:	8d 46 04             	lea    0x4(%esi),%eax
801035f8:	50                   	push   %eax
801035f9:	e8 00 0a 00 00       	call   80103ffe <swtch>
      switchkvm();
801035fe:	e8 cc 29 00 00       	call   80105fcf <switchkvm>
      c->proc = 0;
80103603:	c7 86 ac 00 00 00 00 	movl   $0x0,0xac(%esi)
8010360a:	00 00 00 
8010360d:	83 c4 10             	add    $0x10,%esp
      idle = 0;  // not idle this timeslice
80103610:	bf 00 00 00 00       	mov    $0x0,%edi
80103615:	eb b1                	jmp    801035c8 <scheduler+0x20>
    release(&ptable.lock);
80103617:	83 ec 0c             	sub    $0xc,%esp
8010361a:	68 e0 a5 10 80       	push   $0x8010a5e0
8010361f:	e8 b2 07 00 00       	call   80103dd6 <release>
    if (idle) {
80103624:	83 c4 10             	add    $0x10,%esp
80103627:	85 ff                	test   %edi,%edi
80103629:	74 02                	je     8010362d <scheduler+0x85>
  asm volatile("sti");
8010362b:	fb                   	sti    

// hlt() added by Noah Zentzis, Fall 2016.
static inline void
hlt()
{
  asm volatile("hlt");
8010362c:	f4                   	hlt    
8010362d:	fb                   	sti    
    acquire(&ptable.lock);
8010362e:	83 ec 0c             	sub    $0xc,%esp
80103631:	68 e0 a5 10 80       	push   $0x8010a5e0
80103636:	e8 32 07 00 00       	call   80103d6d <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010363b:	83 c4 10             	add    $0x10,%esp
    idle = 1;  // assume idle unless we schedule a process
8010363e:	bf 01 00 00 00       	mov    $0x1,%edi
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103643:	bb 14 a6 10 80       	mov    $0x8010a614,%ebx
80103648:	eb 81                	jmp    801035cb <scheduler+0x23>

8010364a <sched>:
{
8010364a:	f3 0f 1e fb          	endbr32 
8010364e:	55                   	push   %ebp
8010364f:	89 e5                	mov    %esp,%ebp
80103651:	56                   	push   %esi
80103652:	53                   	push   %ebx
  struct proc *p = myproc();
80103653:	e8 c2 fc ff ff       	call   8010331a <myproc>
80103658:	89 c3                	mov    %eax,%ebx
  if(!holding(&ptable.lock))
8010365a:	83 ec 0c             	sub    $0xc,%esp
8010365d:	68 e0 a5 10 80       	push   $0x8010a5e0
80103662:	e8 c2 06 00 00       	call   80103d29 <holding>
80103667:	83 c4 10             	add    $0x10,%esp
8010366a:	85 c0                	test   %eax,%eax
8010366c:	74 4f                	je     801036bd <sched+0x73>
  if(mycpu()->ncli != 1)
8010366e:	e8 28 fc ff ff       	call   8010329b <mycpu>
80103673:	83 b8 a4 00 00 00 01 	cmpl   $0x1,0xa4(%eax)
8010367a:	75 4e                	jne    801036ca <sched+0x80>
  if(p->state == RUNNING)
8010367c:	83 7b 0c 04          	cmpl   $0x4,0xc(%ebx)
80103680:	74 55                	je     801036d7 <sched+0x8d>
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103682:	9c                   	pushf  
80103683:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80103684:	f6 c4 02             	test   $0x2,%ah
80103687:	75 5b                	jne    801036e4 <sched+0x9a>
  intena = mycpu()->intena;
80103689:	e8 0d fc ff ff       	call   8010329b <mycpu>
8010368e:	8b b0 a8 00 00 00    	mov    0xa8(%eax),%esi
  swtch(&p->context, mycpu()->scheduler);
80103694:	e8 02 fc ff ff       	call   8010329b <mycpu>
80103699:	83 ec 08             	sub    $0x8,%esp
8010369c:	ff 70 04             	pushl  0x4(%eax)
8010369f:	83 c3 1c             	add    $0x1c,%ebx
801036a2:	53                   	push   %ebx
801036a3:	e8 56 09 00 00       	call   80103ffe <swtch>
  mycpu()->intena = intena;
801036a8:	e8 ee fb ff ff       	call   8010329b <mycpu>
801036ad:	89 b0 a8 00 00 00    	mov    %esi,0xa8(%eax)
}
801036b3:	83 c4 10             	add    $0x10,%esp
801036b6:	8d 65 f8             	lea    -0x8(%ebp),%esp
801036b9:	5b                   	pop    %ebx
801036ba:	5e                   	pop    %esi
801036bb:	5d                   	pop    %ebp
801036bc:	c3                   	ret    
    panic("sched ptable.lock");
801036bd:	83 ec 0c             	sub    $0xc,%esp
801036c0:	68 db 6b 10 80       	push   $0x80106bdb
801036c5:	e8 92 cc ff ff       	call   8010035c <panic>
    panic("sched locks");
801036ca:	83 ec 0c             	sub    $0xc,%esp
801036cd:	68 ed 6b 10 80       	push   $0x80106bed
801036d2:	e8 85 cc ff ff       	call   8010035c <panic>
    panic("sched running");
801036d7:	83 ec 0c             	sub    $0xc,%esp
801036da:	68 f9 6b 10 80       	push   $0x80106bf9
801036df:	e8 78 cc ff ff       	call   8010035c <panic>
    panic("sched interruptible");
801036e4:	83 ec 0c             	sub    $0xc,%esp
801036e7:	68 07 6c 10 80       	push   $0x80106c07
801036ec:	e8 6b cc ff ff       	call   8010035c <panic>

801036f1 <exit>:
{
801036f1:	f3 0f 1e fb          	endbr32 
801036f5:	55                   	push   %ebp
801036f6:	89 e5                	mov    %esp,%ebp
801036f8:	56                   	push   %esi
801036f9:	53                   	push   %ebx
  struct proc *curproc = myproc();
801036fa:	e8 1b fc ff ff       	call   8010331a <myproc>
  if(curproc == initproc)
801036ff:	39 05 c0 a5 10 80    	cmp    %eax,0x8010a5c0
80103705:	74 09                	je     80103710 <exit+0x1f>
80103707:	89 c6                	mov    %eax,%esi
  for(fd = 0; fd < NOFILE; fd++){
80103709:	bb 00 00 00 00       	mov    $0x0,%ebx
8010370e:	eb 24                	jmp    80103734 <exit+0x43>
    panic("init exiting");
80103710:	83 ec 0c             	sub    $0xc,%esp
80103713:	68 1b 6c 10 80       	push   $0x80106c1b
80103718:	e8 3f cc ff ff       	call   8010035c <panic>
      fileclose(curproc->ofile[fd]);
8010371d:	83 ec 0c             	sub    $0xc,%esp
80103720:	50                   	push   %eax
80103721:	e8 0e d6 ff ff       	call   80100d34 <fileclose>
      curproc->ofile[fd] = 0;
80103726:	c7 44 9e 28 00 00 00 	movl   $0x0,0x28(%esi,%ebx,4)
8010372d:	00 
8010372e:	83 c4 10             	add    $0x10,%esp
  for(fd = 0; fd < NOFILE; fd++){
80103731:	83 c3 01             	add    $0x1,%ebx
80103734:	83 fb 0f             	cmp    $0xf,%ebx
80103737:	7f 0a                	jg     80103743 <exit+0x52>
    if(curproc->ofile[fd]){
80103739:	8b 44 9e 28          	mov    0x28(%esi,%ebx,4),%eax
8010373d:	85 c0                	test   %eax,%eax
8010373f:	75 dc                	jne    8010371d <exit+0x2c>
80103741:	eb ee                	jmp    80103731 <exit+0x40>
  begin_op();
80103743:	e8 44 f1 ff ff       	call   8010288c <begin_op>
  iput(curproc->cwd);
80103748:	83 ec 0c             	sub    $0xc,%esp
8010374b:	ff 76 68             	pushl  0x68(%esi)
8010374e:	e8 c3 df ff ff       	call   80101716 <iput>
  end_op();
80103753:	e8 b2 f1 ff ff       	call   8010290a <end_op>
  curproc->cwd = 0;
80103758:	c7 46 68 00 00 00 00 	movl   $0x0,0x68(%esi)
  acquire(&ptable.lock);
8010375f:	c7 04 24 e0 a5 10 80 	movl   $0x8010a5e0,(%esp)
80103766:	e8 02 06 00 00       	call   80103d6d <acquire>
  wakeup1(curproc->parent);
8010376b:	8b 46 14             	mov    0x14(%esi),%eax
8010376e:	e8 c6 f9 ff ff       	call   80103139 <wakeup1>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103773:	83 c4 10             	add    $0x10,%esp
80103776:	bb 14 a6 10 80       	mov    $0x8010a614,%ebx
8010377b:	eb 03                	jmp    80103780 <exit+0x8f>
8010377d:	83 eb 80             	sub    $0xffffff80,%ebx
80103780:	81 fb 14 c6 10 80    	cmp    $0x8010c614,%ebx
80103786:	73 1a                	jae    801037a2 <exit+0xb1>
    if(p->parent == curproc){
80103788:	39 73 14             	cmp    %esi,0x14(%ebx)
8010378b:	75 f0                	jne    8010377d <exit+0x8c>
      p->parent = initproc;
8010378d:	a1 c0 a5 10 80       	mov    0x8010a5c0,%eax
80103792:	89 43 14             	mov    %eax,0x14(%ebx)
      if(p->state == ZOMBIE)
80103795:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
80103799:	75 e2                	jne    8010377d <exit+0x8c>
        wakeup1(initproc);
8010379b:	e8 99 f9 ff ff       	call   80103139 <wakeup1>
801037a0:	eb db                	jmp    8010377d <exit+0x8c>
  curproc->state = ZOMBIE;
801037a2:	c7 46 0c 05 00 00 00 	movl   $0x5,0xc(%esi)
  curproc->sz = 0;
801037a9:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
  sched();
801037af:	e8 96 fe ff ff       	call   8010364a <sched>
  panic("zombie exit");
801037b4:	83 ec 0c             	sub    $0xc,%esp
801037b7:	68 28 6c 10 80       	push   $0x80106c28
801037bc:	e8 9b cb ff ff       	call   8010035c <panic>

801037c1 <yield>:
{
801037c1:	f3 0f 1e fb          	endbr32 
801037c5:	55                   	push   %ebp
801037c6:	89 e5                	mov    %esp,%ebp
801037c8:	53                   	push   %ebx
801037c9:	83 ec 04             	sub    $0x4,%esp
  struct proc *curproc = myproc();
801037cc:	e8 49 fb ff ff       	call   8010331a <myproc>
801037d1:	89 c3                	mov    %eax,%ebx
  acquire(&ptable.lock);  //DOC: yieldlock
801037d3:	83 ec 0c             	sub    $0xc,%esp
801037d6:	68 e0 a5 10 80       	push   $0x8010a5e0
801037db:	e8 8d 05 00 00       	call   80103d6d <acquire>
  curproc->state = RUNNABLE;
801037e0:	c7 43 0c 03 00 00 00 	movl   $0x3,0xc(%ebx)
  sched();
801037e7:	e8 5e fe ff ff       	call   8010364a <sched>
  release(&ptable.lock);
801037ec:	c7 04 24 e0 a5 10 80 	movl   $0x8010a5e0,(%esp)
801037f3:	e8 de 05 00 00       	call   80103dd6 <release>
}
801037f8:	83 c4 10             	add    $0x10,%esp
801037fb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801037fe:	c9                   	leave  
801037ff:	c3                   	ret    

80103800 <sleep>:
{
80103800:	f3 0f 1e fb          	endbr32 
80103804:	55                   	push   %ebp
80103805:	89 e5                	mov    %esp,%ebp
80103807:	56                   	push   %esi
80103808:	53                   	push   %ebx
80103809:	8b 75 0c             	mov    0xc(%ebp),%esi
  struct proc *p = myproc();
8010380c:	e8 09 fb ff ff       	call   8010331a <myproc>
  if(p == 0)
80103811:	85 c0                	test   %eax,%eax
80103813:	74 72                	je     80103887 <sleep+0x87>
80103815:	89 c3                	mov    %eax,%ebx
  if(lk != &ptable.lock){  //DOC: sleeplock0
80103817:	81 fe e0 a5 10 80    	cmp    $0x8010a5e0,%esi
8010381d:	74 20                	je     8010383f <sleep+0x3f>
    acquire(&ptable.lock);  //DOC: sleeplock1
8010381f:	83 ec 0c             	sub    $0xc,%esp
80103822:	68 e0 a5 10 80       	push   $0x8010a5e0
80103827:	e8 41 05 00 00       	call   80103d6d <acquire>
    if (lk) release(lk);
8010382c:	83 c4 10             	add    $0x10,%esp
8010382f:	85 f6                	test   %esi,%esi
80103831:	74 0c                	je     8010383f <sleep+0x3f>
80103833:	83 ec 0c             	sub    $0xc,%esp
80103836:	56                   	push   %esi
80103837:	e8 9a 05 00 00       	call   80103dd6 <release>
8010383c:	83 c4 10             	add    $0x10,%esp
  p->chan = chan;
8010383f:	8b 45 08             	mov    0x8(%ebp),%eax
80103842:	89 43 20             	mov    %eax,0x20(%ebx)
  p->state = SLEEPING;
80103845:	c7 43 0c 02 00 00 00 	movl   $0x2,0xc(%ebx)
  sched();
8010384c:	e8 f9 fd ff ff       	call   8010364a <sched>
  p->chan = 0;
80103851:	c7 43 20 00 00 00 00 	movl   $0x0,0x20(%ebx)
  if(lk != &ptable.lock){  //DOC: sleeplock2
80103858:	81 fe e0 a5 10 80    	cmp    $0x8010a5e0,%esi
8010385e:	74 20                	je     80103880 <sleep+0x80>
    release(&ptable.lock);
80103860:	83 ec 0c             	sub    $0xc,%esp
80103863:	68 e0 a5 10 80       	push   $0x8010a5e0
80103868:	e8 69 05 00 00       	call   80103dd6 <release>
    if (lk) acquire(lk);
8010386d:	83 c4 10             	add    $0x10,%esp
80103870:	85 f6                	test   %esi,%esi
80103872:	74 0c                	je     80103880 <sleep+0x80>
80103874:	83 ec 0c             	sub    $0xc,%esp
80103877:	56                   	push   %esi
80103878:	e8 f0 04 00 00       	call   80103d6d <acquire>
8010387d:	83 c4 10             	add    $0x10,%esp
}
80103880:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103883:	5b                   	pop    %ebx
80103884:	5e                   	pop    %esi
80103885:	5d                   	pop    %ebp
80103886:	c3                   	ret    
    panic("sleep");
80103887:	83 ec 0c             	sub    $0xc,%esp
8010388a:	68 34 6c 10 80       	push   $0x80106c34
8010388f:	e8 c8 ca ff ff       	call   8010035c <panic>

80103894 <wait>:
{
80103894:	f3 0f 1e fb          	endbr32 
80103898:	55                   	push   %ebp
80103899:	89 e5                	mov    %esp,%ebp
8010389b:	56                   	push   %esi
8010389c:	53                   	push   %ebx
  struct proc *curproc = myproc();
8010389d:	e8 78 fa ff ff       	call   8010331a <myproc>
801038a2:	89 c6                	mov    %eax,%esi
  acquire(&ptable.lock);
801038a4:	83 ec 0c             	sub    $0xc,%esp
801038a7:	68 e0 a5 10 80       	push   $0x8010a5e0
801038ac:	e8 bc 04 00 00       	call   80103d6d <acquire>
801038b1:	83 c4 10             	add    $0x10,%esp
    havekids = 0;
801038b4:	b8 00 00 00 00       	mov    $0x0,%eax
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801038b9:	bb 14 a6 10 80       	mov    $0x8010a614,%ebx
801038be:	eb 5b                	jmp    8010391b <wait+0x87>
        pid = p->pid;
801038c0:	8b 73 10             	mov    0x10(%ebx),%esi
        kfree(p->kstack);
801038c3:	83 ec 0c             	sub    $0xc,%esp
801038c6:	ff 73 08             	pushl  0x8(%ebx)
801038c9:	e8 9a e7 ff ff       	call   80102068 <kfree>
        p->kstack = 0;
801038ce:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
        freevm(p->pgdir);
801038d5:	83 c4 04             	add    $0x4,%esp
801038d8:	ff 73 04             	pushl  0x4(%ebx)
801038db:	e8 ac 2a 00 00       	call   8010638c <freevm>
        p->pid = 0;
801038e0:	c7 43 10 00 00 00 00 	movl   $0x0,0x10(%ebx)
        p->parent = 0;
801038e7:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
        p->name[0] = 0;
801038ee:	c6 43 6c 00          	movb   $0x0,0x6c(%ebx)
        p->killed = 0;
801038f2:	c7 43 24 00 00 00 00 	movl   $0x0,0x24(%ebx)
        p->state = UNUSED;
801038f9:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
        release(&ptable.lock);
80103900:	c7 04 24 e0 a5 10 80 	movl   $0x8010a5e0,(%esp)
80103907:	e8 ca 04 00 00       	call   80103dd6 <release>
        return pid;
8010390c:	89 f0                	mov    %esi,%eax
8010390e:	83 c4 10             	add    $0x10,%esp
}
80103911:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103914:	5b                   	pop    %ebx
80103915:	5e                   	pop    %esi
80103916:	5d                   	pop    %ebp
80103917:	c3                   	ret    
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103918:	83 eb 80             	sub    $0xffffff80,%ebx
8010391b:	81 fb 14 c6 10 80    	cmp    $0x8010c614,%ebx
80103921:	73 12                	jae    80103935 <wait+0xa1>
      if(p->parent != curproc)
80103923:	39 73 14             	cmp    %esi,0x14(%ebx)
80103926:	75 f0                	jne    80103918 <wait+0x84>
      if(p->state == ZOMBIE){
80103928:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
8010392c:	74 92                	je     801038c0 <wait+0x2c>
      havekids = 1;
8010392e:	b8 01 00 00 00       	mov    $0x1,%eax
80103933:	eb e3                	jmp    80103918 <wait+0x84>
    if(!havekids || curproc->killed){
80103935:	85 c0                	test   %eax,%eax
80103937:	74 06                	je     8010393f <wait+0xab>
80103939:	83 7e 24 00          	cmpl   $0x0,0x24(%esi)
8010393d:	74 17                	je     80103956 <wait+0xc2>
      release(&ptable.lock);
8010393f:	83 ec 0c             	sub    $0xc,%esp
80103942:	68 e0 a5 10 80       	push   $0x8010a5e0
80103947:	e8 8a 04 00 00       	call   80103dd6 <release>
      return -1;
8010394c:	83 c4 10             	add    $0x10,%esp
8010394f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103954:	eb bb                	jmp    80103911 <wait+0x7d>
    sleep(curproc, &ptable.lock);  //DOC: wait-sleep
80103956:	83 ec 08             	sub    $0x8,%esp
80103959:	68 e0 a5 10 80       	push   $0x8010a5e0
8010395e:	56                   	push   %esi
8010395f:	e8 9c fe ff ff       	call   80103800 <sleep>
    havekids = 0;
80103964:	83 c4 10             	add    $0x10,%esp
80103967:	e9 48 ff ff ff       	jmp    801038b4 <wait+0x20>

8010396c <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
8010396c:	f3 0f 1e fb          	endbr32 
80103970:	55                   	push   %ebp
80103971:	89 e5                	mov    %esp,%ebp
80103973:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);
80103976:	68 e0 a5 10 80       	push   $0x8010a5e0
8010397b:	e8 ed 03 00 00       	call   80103d6d <acquire>
  wakeup1(chan);
80103980:	8b 45 08             	mov    0x8(%ebp),%eax
80103983:	e8 b1 f7 ff ff       	call   80103139 <wakeup1>
  release(&ptable.lock);
80103988:	c7 04 24 e0 a5 10 80 	movl   $0x8010a5e0,(%esp)
8010398f:	e8 42 04 00 00       	call   80103dd6 <release>
}
80103994:	83 c4 10             	add    $0x10,%esp
80103997:	c9                   	leave  
80103998:	c3                   	ret    

80103999 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80103999:	f3 0f 1e fb          	endbr32 
8010399d:	55                   	push   %ebp
8010399e:	89 e5                	mov    %esp,%ebp
801039a0:	53                   	push   %ebx
801039a1:	83 ec 10             	sub    $0x10,%esp
801039a4:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *p;

  acquire(&ptable.lock);
801039a7:	68 e0 a5 10 80       	push   $0x8010a5e0
801039ac:	e8 bc 03 00 00       	call   80103d6d <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801039b1:	83 c4 10             	add    $0x10,%esp
801039b4:	b8 14 a6 10 80       	mov    $0x8010a614,%eax
801039b9:	3d 14 c6 10 80       	cmp    $0x8010c614,%eax
801039be:	73 3a                	jae    801039fa <kill+0x61>
    if(p->pid == pid){
801039c0:	39 58 10             	cmp    %ebx,0x10(%eax)
801039c3:	74 05                	je     801039ca <kill+0x31>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801039c5:	83 e8 80             	sub    $0xffffff80,%eax
801039c8:	eb ef                	jmp    801039b9 <kill+0x20>
      p->killed = 1;
801039ca:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
801039d1:	83 78 0c 02          	cmpl   $0x2,0xc(%eax)
801039d5:	74 1a                	je     801039f1 <kill+0x58>
        p->state = RUNNABLE;
      release(&ptable.lock);
801039d7:	83 ec 0c             	sub    $0xc,%esp
801039da:	68 e0 a5 10 80       	push   $0x8010a5e0
801039df:	e8 f2 03 00 00       	call   80103dd6 <release>
      return 0;
801039e4:	83 c4 10             	add    $0x10,%esp
801039e7:	b8 00 00 00 00       	mov    $0x0,%eax
    }
  }
  release(&ptable.lock);
  return -1;
}
801039ec:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801039ef:	c9                   	leave  
801039f0:	c3                   	ret    
        p->state = RUNNABLE;
801039f1:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
801039f8:	eb dd                	jmp    801039d7 <kill+0x3e>
  release(&ptable.lock);
801039fa:	83 ec 0c             	sub    $0xc,%esp
801039fd:	68 e0 a5 10 80       	push   $0x8010a5e0
80103a02:	e8 cf 03 00 00       	call   80103dd6 <release>
  return -1;
80103a07:	83 c4 10             	add    $0x10,%esp
80103a0a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103a0f:	eb db                	jmp    801039ec <kill+0x53>

80103a11 <procdumpP1>:
  return;
}
#elif defined(CS333_P1)
void
procdumpP1(struct proc *p, char *state_string)
{
80103a11:	f3 0f 1e fb          	endbr32 
80103a15:	55                   	push   %ebp
80103a16:	89 e5                	mov    %esp,%ebp
80103a18:	53                   	push   %ebx
80103a19:	83 ec 08             	sub    $0x8,%esp
80103a1c:	8b 4d 08             	mov    0x8(%ebp),%ecx
  uint elapsed_in_ms = ticks - p->start_ticks;
80103a1f:	8b 1d 80 55 11 80    	mov    0x80115580,%ebx
80103a25:	2b 59 7c             	sub    0x7c(%ecx),%ebx
  uint elapsed_in_sec = elapsed_in_ms / 1000;
80103a28:	ba d3 4d 62 10       	mov    $0x10624dd3,%edx
80103a2d:	89 d8                	mov    %ebx,%eax
80103a2f:	f7 e2                	mul    %edx
80103a31:	c1 ea 06             	shr    $0x6,%edx
  uint elapsed_decimal = elapsed_in_ms % 1000;
80103a34:	69 c2 e8 03 00 00    	imul   $0x3e8,%edx,%eax
80103a3a:	29 c3                	sub    %eax,%ebx
80103a3c:	89 d8                	mov    %ebx,%eax

  cprintf("%d\t%s\t\t%d.%d\t%s\t%d\t", p->pid, p->name, elapsed_in_sec, elapsed_decimal, state_string, p->sz);
80103a3e:	8d 59 6c             	lea    0x6c(%ecx),%ebx
80103a41:	ff 31                	pushl  (%ecx)
80103a43:	ff 75 0c             	pushl  0xc(%ebp)
80103a46:	50                   	push   %eax
80103a47:	52                   	push   %edx
80103a48:	53                   	push   %ebx
80103a49:	ff 71 10             	pushl  0x10(%ecx)
80103a4c:	68 3a 6c 10 80       	push   $0x80106c3a
80103a51:	e8 d3 cb ff ff       	call   80100629 <cprintf>
}
80103a56:	83 c4 20             	add    $0x20,%esp
80103a59:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103a5c:	c9                   	leave  
80103a5d:	c3                   	ret    

80103a5e <procdump>:
#endif

void
procdump(void)
{
80103a5e:	f3 0f 1e fb          	endbr32 
80103a62:	55                   	push   %ebp
80103a63:	89 e5                	mov    %esp,%ebp
80103a65:	56                   	push   %esi
80103a66:	53                   	push   %ebx
80103a67:	83 ec 3c             	sub    $0x3c,%esp
#define HEADER "\nPID\tName         Elapsed\tState\tSize\t PCs\n"
#else
#define HEADER "\n"
#endif

  cprintf(HEADER);  // not conditionally compiled as must work in all project states
80103a6a:	68 a8 6c 10 80       	push   $0x80106ca8
80103a6f:	e8 b5 cb ff ff       	call   80100629 <cprintf>

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103a74:	83 c4 10             	add    $0x10,%esp
80103a77:	bb 14 a6 10 80       	mov    $0x8010a614,%ebx
80103a7c:	eb 2b                	jmp    80103aa9 <procdump+0x4b>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
80103a7e:	b8 4e 6c 10 80       	mov    $0x80106c4e,%eax
    // see TODOs above this function
    // P2 and P3 are identical and the P4 change is minor
#if defined(CS333_P2)
    procdumpP2P3P4(p, state);
#elif defined(CS333_P1)
    procdumpP1(p, state);
80103a83:	83 ec 08             	sub    $0x8,%esp
80103a86:	50                   	push   %eax
80103a87:	53                   	push   %ebx
80103a88:	e8 84 ff ff ff       	call   80103a11 <procdumpP1>
#else
    cprintf("%d\t%s\t%s\t", p->pid, p->name, state);
#endif

    if(p->state == SLEEPING){
80103a8d:	83 c4 10             	add    $0x10,%esp
80103a90:	83 7b 0c 02          	cmpl   $0x2,0xc(%ebx)
80103a94:	74 39                	je     80103acf <procdump+0x71>
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80103a96:	83 ec 0c             	sub    $0xc,%esp
80103a99:	68 fb 6f 10 80       	push   $0x80106ffb
80103a9e:	e8 86 cb ff ff       	call   80100629 <cprintf>
80103aa3:	83 c4 10             	add    $0x10,%esp
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103aa6:	83 eb 80             	sub    $0xffffff80,%ebx
80103aa9:	81 fb 14 c6 10 80    	cmp    $0x8010c614,%ebx
80103aaf:	73 61                	jae    80103b12 <procdump+0xb4>
    if(p->state == UNUSED)
80103ab1:	8b 43 0c             	mov    0xc(%ebx),%eax
80103ab4:	85 c0                	test   %eax,%eax
80103ab6:	74 ee                	je     80103aa6 <procdump+0x48>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80103ab8:	83 f8 05             	cmp    $0x5,%eax
80103abb:	77 c1                	ja     80103a7e <procdump+0x20>
80103abd:	8b 04 85 d4 6c 10 80 	mov    -0x7fef932c(,%eax,4),%eax
80103ac4:	85 c0                	test   %eax,%eax
80103ac6:	75 bb                	jne    80103a83 <procdump+0x25>
      state = "???";
80103ac8:	b8 4e 6c 10 80       	mov    $0x80106c4e,%eax
80103acd:	eb b4                	jmp    80103a83 <procdump+0x25>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80103acf:	8b 43 1c             	mov    0x1c(%ebx),%eax
80103ad2:	8b 40 0c             	mov    0xc(%eax),%eax
80103ad5:	83 c0 08             	add    $0x8,%eax
80103ad8:	83 ec 08             	sub    $0x8,%esp
80103adb:	8d 55 d0             	lea    -0x30(%ebp),%edx
80103ade:	52                   	push   %edx
80103adf:	50                   	push   %eax
80103ae0:	e8 57 01 00 00       	call   80103c3c <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80103ae5:	83 c4 10             	add    $0x10,%esp
80103ae8:	be 00 00 00 00       	mov    $0x0,%esi
80103aed:	eb 14                	jmp    80103b03 <procdump+0xa5>
        cprintf(" %p", pc[i]);
80103aef:	83 ec 08             	sub    $0x8,%esp
80103af2:	50                   	push   %eax
80103af3:	68 a1 66 10 80       	push   $0x801066a1
80103af8:	e8 2c cb ff ff       	call   80100629 <cprintf>
      for(i=0; i<10 && pc[i] != 0; i++)
80103afd:	83 c6 01             	add    $0x1,%esi
80103b00:	83 c4 10             	add    $0x10,%esp
80103b03:	83 fe 09             	cmp    $0x9,%esi
80103b06:	7f 8e                	jg     80103a96 <procdump+0x38>
80103b08:	8b 44 b5 d0          	mov    -0x30(%ebp,%esi,4),%eax
80103b0c:	85 c0                	test   %eax,%eax
80103b0e:	75 df                	jne    80103aef <procdump+0x91>
80103b10:	eb 84                	jmp    80103a96 <procdump+0x38>
  }
#ifdef CS333_P1
  cprintf("$ ");  // simulate shell prompt
80103b12:	83 ec 0c             	sub    $0xc,%esp
80103b15:	68 52 6c 10 80       	push   $0x80106c52
80103b1a:	e8 0a cb ff ff       	call   80100629 <cprintf>
#endif // CS333_P1
}
80103b1f:	83 c4 10             	add    $0x10,%esp
80103b22:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103b25:	5b                   	pop    %ebx
80103b26:	5e                   	pop    %esi
80103b27:	5d                   	pop    %ebp
80103b28:	c3                   	ret    

80103b29 <initsleeplock>:
#include "spinlock.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
80103b29:	f3 0f 1e fb          	endbr32 
80103b2d:	55                   	push   %ebp
80103b2e:	89 e5                	mov    %esp,%ebp
80103b30:	53                   	push   %ebx
80103b31:	83 ec 0c             	sub    $0xc,%esp
80103b34:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&lk->lk, "sleep lock");
80103b37:	68 ec 6c 10 80       	push   $0x80106cec
80103b3c:	8d 43 04             	lea    0x4(%ebx),%eax
80103b3f:	50                   	push   %eax
80103b40:	e8 d8 00 00 00       	call   80103c1d <initlock>
  lk->name = name;
80103b45:	8b 45 0c             	mov    0xc(%ebp),%eax
80103b48:	89 43 38             	mov    %eax,0x38(%ebx)
  lk->locked = 0;
80103b4b:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103b51:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
}
80103b58:	83 c4 10             	add    $0x10,%esp
80103b5b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103b5e:	c9                   	leave  
80103b5f:	c3                   	ret    

80103b60 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
80103b60:	f3 0f 1e fb          	endbr32 
80103b64:	55                   	push   %ebp
80103b65:	89 e5                	mov    %esp,%ebp
80103b67:	56                   	push   %esi
80103b68:	53                   	push   %ebx
80103b69:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103b6c:	8d 73 04             	lea    0x4(%ebx),%esi
80103b6f:	83 ec 0c             	sub    $0xc,%esp
80103b72:	56                   	push   %esi
80103b73:	e8 f5 01 00 00       	call   80103d6d <acquire>
  while (lk->locked) {
80103b78:	83 c4 10             	add    $0x10,%esp
80103b7b:	83 3b 00             	cmpl   $0x0,(%ebx)
80103b7e:	74 0f                	je     80103b8f <acquiresleep+0x2f>
    sleep(lk, &lk->lk);
80103b80:	83 ec 08             	sub    $0x8,%esp
80103b83:	56                   	push   %esi
80103b84:	53                   	push   %ebx
80103b85:	e8 76 fc ff ff       	call   80103800 <sleep>
80103b8a:	83 c4 10             	add    $0x10,%esp
80103b8d:	eb ec                	jmp    80103b7b <acquiresleep+0x1b>
  }
  lk->locked = 1;
80103b8f:	c7 03 01 00 00 00    	movl   $0x1,(%ebx)
  lk->pid = myproc()->pid;
80103b95:	e8 80 f7 ff ff       	call   8010331a <myproc>
80103b9a:	8b 40 10             	mov    0x10(%eax),%eax
80103b9d:	89 43 3c             	mov    %eax,0x3c(%ebx)
  release(&lk->lk);
80103ba0:	83 ec 0c             	sub    $0xc,%esp
80103ba3:	56                   	push   %esi
80103ba4:	e8 2d 02 00 00       	call   80103dd6 <release>
}
80103ba9:	83 c4 10             	add    $0x10,%esp
80103bac:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103baf:	5b                   	pop    %ebx
80103bb0:	5e                   	pop    %esi
80103bb1:	5d                   	pop    %ebp
80103bb2:	c3                   	ret    

80103bb3 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
80103bb3:	f3 0f 1e fb          	endbr32 
80103bb7:	55                   	push   %ebp
80103bb8:	89 e5                	mov    %esp,%ebp
80103bba:	56                   	push   %esi
80103bbb:	53                   	push   %ebx
80103bbc:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103bbf:	8d 73 04             	lea    0x4(%ebx),%esi
80103bc2:	83 ec 0c             	sub    $0xc,%esp
80103bc5:	56                   	push   %esi
80103bc6:	e8 a2 01 00 00       	call   80103d6d <acquire>
  lk->locked = 0;
80103bcb:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103bd1:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
  wakeup(lk);
80103bd8:	89 1c 24             	mov    %ebx,(%esp)
80103bdb:	e8 8c fd ff ff       	call   8010396c <wakeup>
  release(&lk->lk);
80103be0:	89 34 24             	mov    %esi,(%esp)
80103be3:	e8 ee 01 00 00       	call   80103dd6 <release>
}
80103be8:	83 c4 10             	add    $0x10,%esp
80103beb:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103bee:	5b                   	pop    %ebx
80103bef:	5e                   	pop    %esi
80103bf0:	5d                   	pop    %ebp
80103bf1:	c3                   	ret    

80103bf2 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
80103bf2:	f3 0f 1e fb          	endbr32 
80103bf6:	55                   	push   %ebp
80103bf7:	89 e5                	mov    %esp,%ebp
80103bf9:	56                   	push   %esi
80103bfa:	53                   	push   %ebx
80103bfb:	8b 75 08             	mov    0x8(%ebp),%esi
  int r;
  
  acquire(&lk->lk);
80103bfe:	8d 5e 04             	lea    0x4(%esi),%ebx
80103c01:	83 ec 0c             	sub    $0xc,%esp
80103c04:	53                   	push   %ebx
80103c05:	e8 63 01 00 00       	call   80103d6d <acquire>
  r = lk->locked;
80103c0a:	8b 36                	mov    (%esi),%esi
  release(&lk->lk);
80103c0c:	89 1c 24             	mov    %ebx,(%esp)
80103c0f:	e8 c2 01 00 00       	call   80103dd6 <release>
  return r;
}
80103c14:	89 f0                	mov    %esi,%eax
80103c16:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103c19:	5b                   	pop    %ebx
80103c1a:	5e                   	pop    %esi
80103c1b:	5d                   	pop    %ebp
80103c1c:	c3                   	ret    

80103c1d <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80103c1d:	f3 0f 1e fb          	endbr32 
80103c21:	55                   	push   %ebp
80103c22:	89 e5                	mov    %esp,%ebp
80103c24:	8b 45 08             	mov    0x8(%ebp),%eax
  lk->name = name;
80103c27:	8b 55 0c             	mov    0xc(%ebp),%edx
80103c2a:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80103c2d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80103c33:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80103c3a:	5d                   	pop    %ebp
80103c3b:	c3                   	ret    

80103c3c <getcallerpcs>:
}

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80103c3c:	f3 0f 1e fb          	endbr32 
80103c40:	55                   	push   %ebp
80103c41:	89 e5                	mov    %esp,%ebp
80103c43:	53                   	push   %ebx
80103c44:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  uint *ebp;
  int i;

  ebp = (uint*)v - 2;
80103c47:	8b 45 08             	mov    0x8(%ebp),%eax
80103c4a:	8d 50 f8             	lea    -0x8(%eax),%edx
  for(i = 0; i < 10; i++){
80103c4d:	b8 00 00 00 00       	mov    $0x0,%eax
80103c52:	83 f8 09             	cmp    $0x9,%eax
80103c55:	7f 25                	jg     80103c7c <getcallerpcs+0x40>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80103c57:	8d 9a 00 00 00 80    	lea    -0x80000000(%edx),%ebx
80103c5d:	81 fb fe ff ff 7f    	cmp    $0x7ffffffe,%ebx
80103c63:	77 17                	ja     80103c7c <getcallerpcs+0x40>
      break;
    pcs[i] = ebp[1];     // saved %eip
80103c65:	8b 5a 04             	mov    0x4(%edx),%ebx
80103c68:	89 1c 81             	mov    %ebx,(%ecx,%eax,4)
    ebp = (uint*)ebp[0]; // saved %ebp
80103c6b:	8b 12                	mov    (%edx),%edx
  for(i = 0; i < 10; i++){
80103c6d:	83 c0 01             	add    $0x1,%eax
80103c70:	eb e0                	jmp    80103c52 <getcallerpcs+0x16>
  }
  for(; i < 10; i++)
    pcs[i] = 0;
80103c72:	c7 04 81 00 00 00 00 	movl   $0x0,(%ecx,%eax,4)
  for(; i < 10; i++)
80103c79:	83 c0 01             	add    $0x1,%eax
80103c7c:	83 f8 09             	cmp    $0x9,%eax
80103c7f:	7e f1                	jle    80103c72 <getcallerpcs+0x36>
}
80103c81:	5b                   	pop    %ebx
80103c82:	5d                   	pop    %ebp
80103c83:	c3                   	ret    

80103c84 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80103c84:	f3 0f 1e fb          	endbr32 
80103c88:	55                   	push   %ebp
80103c89:	89 e5                	mov    %esp,%ebp
80103c8b:	53                   	push   %ebx
80103c8c:	83 ec 04             	sub    $0x4,%esp
80103c8f:	9c                   	pushf  
80103c90:	5b                   	pop    %ebx
  asm volatile("cli");
80103c91:	fa                   	cli    
  int eflags;

  eflags = readeflags();
  cli();
  if(mycpu()->ncli == 0)
80103c92:	e8 04 f6 ff ff       	call   8010329b <mycpu>
80103c97:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103c9e:	74 12                	je     80103cb2 <pushcli+0x2e>
    mycpu()->intena = eflags & FL_IF;
  mycpu()->ncli += 1;
80103ca0:	e8 f6 f5 ff ff       	call   8010329b <mycpu>
80103ca5:	83 80 a4 00 00 00 01 	addl   $0x1,0xa4(%eax)
}
80103cac:	83 c4 04             	add    $0x4,%esp
80103caf:	5b                   	pop    %ebx
80103cb0:	5d                   	pop    %ebp
80103cb1:	c3                   	ret    
    mycpu()->intena = eflags & FL_IF;
80103cb2:	e8 e4 f5 ff ff       	call   8010329b <mycpu>
80103cb7:	81 e3 00 02 00 00    	and    $0x200,%ebx
80103cbd:	89 98 a8 00 00 00    	mov    %ebx,0xa8(%eax)
80103cc3:	eb db                	jmp    80103ca0 <pushcli+0x1c>

80103cc5 <popcli>:

void
popcli(void)
{
80103cc5:	f3 0f 1e fb          	endbr32 
80103cc9:	55                   	push   %ebp
80103cca:	89 e5                	mov    %esp,%ebp
80103ccc:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103ccf:	9c                   	pushf  
80103cd0:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80103cd1:	f6 c4 02             	test   $0x2,%ah
80103cd4:	75 28                	jne    80103cfe <popcli+0x39>
    panic("popcli - interruptible");
  if(--mycpu()->ncli < 0)
80103cd6:	e8 c0 f5 ff ff       	call   8010329b <mycpu>
80103cdb:	8b 88 a4 00 00 00    	mov    0xa4(%eax),%ecx
80103ce1:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103ce4:	89 90 a4 00 00 00    	mov    %edx,0xa4(%eax)
80103cea:	85 d2                	test   %edx,%edx
80103cec:	78 1d                	js     80103d0b <popcli+0x46>
    panic("popcli");
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103cee:	e8 a8 f5 ff ff       	call   8010329b <mycpu>
80103cf3:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103cfa:	74 1c                	je     80103d18 <popcli+0x53>
    sti();
}
80103cfc:	c9                   	leave  
80103cfd:	c3                   	ret    
    panic("popcli - interruptible");
80103cfe:	83 ec 0c             	sub    $0xc,%esp
80103d01:	68 f7 6c 10 80       	push   $0x80106cf7
80103d06:	e8 51 c6 ff ff       	call   8010035c <panic>
    panic("popcli");
80103d0b:	83 ec 0c             	sub    $0xc,%esp
80103d0e:	68 0e 6d 10 80       	push   $0x80106d0e
80103d13:	e8 44 c6 ff ff       	call   8010035c <panic>
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103d18:	e8 7e f5 ff ff       	call   8010329b <mycpu>
80103d1d:	83 b8 a8 00 00 00 00 	cmpl   $0x0,0xa8(%eax)
80103d24:	74 d6                	je     80103cfc <popcli+0x37>
  asm volatile("sti");
80103d26:	fb                   	sti    
}
80103d27:	eb d3                	jmp    80103cfc <popcli+0x37>

80103d29 <holding>:
{
80103d29:	f3 0f 1e fb          	endbr32 
80103d2d:	55                   	push   %ebp
80103d2e:	89 e5                	mov    %esp,%ebp
80103d30:	53                   	push   %ebx
80103d31:	83 ec 04             	sub    $0x4,%esp
80103d34:	8b 5d 08             	mov    0x8(%ebp),%ebx
  pushcli();
80103d37:	e8 48 ff ff ff       	call   80103c84 <pushcli>
  r = lock->locked && lock->cpu == mycpu();
80103d3c:	83 3b 00             	cmpl   $0x0,(%ebx)
80103d3f:	75 12                	jne    80103d53 <holding+0x2a>
80103d41:	bb 00 00 00 00       	mov    $0x0,%ebx
  popcli();
80103d46:	e8 7a ff ff ff       	call   80103cc5 <popcli>
}
80103d4b:	89 d8                	mov    %ebx,%eax
80103d4d:	83 c4 04             	add    $0x4,%esp
80103d50:	5b                   	pop    %ebx
80103d51:	5d                   	pop    %ebp
80103d52:	c3                   	ret    
  r = lock->locked && lock->cpu == mycpu();
80103d53:	8b 5b 08             	mov    0x8(%ebx),%ebx
80103d56:	e8 40 f5 ff ff       	call   8010329b <mycpu>
80103d5b:	39 c3                	cmp    %eax,%ebx
80103d5d:	74 07                	je     80103d66 <holding+0x3d>
80103d5f:	bb 00 00 00 00       	mov    $0x0,%ebx
80103d64:	eb e0                	jmp    80103d46 <holding+0x1d>
80103d66:	bb 01 00 00 00       	mov    $0x1,%ebx
80103d6b:	eb d9                	jmp    80103d46 <holding+0x1d>

80103d6d <acquire>:
{
80103d6d:	f3 0f 1e fb          	endbr32 
80103d71:	55                   	push   %ebp
80103d72:	89 e5                	mov    %esp,%ebp
80103d74:	53                   	push   %ebx
80103d75:	83 ec 04             	sub    $0x4,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80103d78:	e8 07 ff ff ff       	call   80103c84 <pushcli>
  if(holding(lk))
80103d7d:	83 ec 0c             	sub    $0xc,%esp
80103d80:	ff 75 08             	pushl  0x8(%ebp)
80103d83:	e8 a1 ff ff ff       	call   80103d29 <holding>
80103d88:	83 c4 10             	add    $0x10,%esp
80103d8b:	85 c0                	test   %eax,%eax
80103d8d:	75 3a                	jne    80103dc9 <acquire+0x5c>
  while(xchg(&lk->locked, 1) != 0)
80103d8f:	8b 55 08             	mov    0x8(%ebp),%edx
  asm volatile("lock; xchgl %0, %1" :
80103d92:	b8 01 00 00 00       	mov    $0x1,%eax
80103d97:	f0 87 02             	lock xchg %eax,(%edx)
80103d9a:	85 c0                	test   %eax,%eax
80103d9c:	75 f1                	jne    80103d8f <acquire+0x22>
  __sync_synchronize();
80103d9e:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  lk->cpu = mycpu();
80103da3:	8b 5d 08             	mov    0x8(%ebp),%ebx
80103da6:	e8 f0 f4 ff ff       	call   8010329b <mycpu>
80103dab:	89 43 08             	mov    %eax,0x8(%ebx)
  getcallerpcs(&lk, lk->pcs);
80103dae:	8b 45 08             	mov    0x8(%ebp),%eax
80103db1:	83 c0 0c             	add    $0xc,%eax
80103db4:	83 ec 08             	sub    $0x8,%esp
80103db7:	50                   	push   %eax
80103db8:	8d 45 08             	lea    0x8(%ebp),%eax
80103dbb:	50                   	push   %eax
80103dbc:	e8 7b fe ff ff       	call   80103c3c <getcallerpcs>
}
80103dc1:	83 c4 10             	add    $0x10,%esp
80103dc4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103dc7:	c9                   	leave  
80103dc8:	c3                   	ret    
    panic("acquire");
80103dc9:	83 ec 0c             	sub    $0xc,%esp
80103dcc:	68 15 6d 10 80       	push   $0x80106d15
80103dd1:	e8 86 c5 ff ff       	call   8010035c <panic>

80103dd6 <release>:
{
80103dd6:	f3 0f 1e fb          	endbr32 
80103dda:	55                   	push   %ebp
80103ddb:	89 e5                	mov    %esp,%ebp
80103ddd:	53                   	push   %ebx
80103dde:	83 ec 10             	sub    $0x10,%esp
80103de1:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holding(lk))
80103de4:	53                   	push   %ebx
80103de5:	e8 3f ff ff ff       	call   80103d29 <holding>
80103dea:	83 c4 10             	add    $0x10,%esp
80103ded:	85 c0                	test   %eax,%eax
80103def:	74 23                	je     80103e14 <release+0x3e>
  lk->pcs[0] = 0;
80103df1:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
  lk->cpu = 0;
80103df8:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
  __sync_synchronize();
80103dff:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  asm volatile("movl $0, %0" : "+m" (lk->locked) : );
80103e04:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  popcli();
80103e0a:	e8 b6 fe ff ff       	call   80103cc5 <popcli>
}
80103e0f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103e12:	c9                   	leave  
80103e13:	c3                   	ret    
    panic("release");
80103e14:	83 ec 0c             	sub    $0xc,%esp
80103e17:	68 1d 6d 10 80       	push   $0x80106d1d
80103e1c:	e8 3b c5 ff ff       	call   8010035c <panic>

80103e21 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80103e21:	f3 0f 1e fb          	endbr32 
80103e25:	55                   	push   %ebp
80103e26:	89 e5                	mov    %esp,%ebp
80103e28:	57                   	push   %edi
80103e29:	53                   	push   %ebx
80103e2a:	8b 55 08             	mov    0x8(%ebp),%edx
80103e2d:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e30:	8b 4d 10             	mov    0x10(%ebp),%ecx
  if ((int)dst%4 == 0 && n%4 == 0){
80103e33:	f6 c2 03             	test   $0x3,%dl
80103e36:	75 25                	jne    80103e5d <memset+0x3c>
80103e38:	f6 c1 03             	test   $0x3,%cl
80103e3b:	75 20                	jne    80103e5d <memset+0x3c>
    c &= 0xFF;
80103e3d:	0f b6 f8             	movzbl %al,%edi
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80103e40:	c1 e9 02             	shr    $0x2,%ecx
80103e43:	c1 e0 18             	shl    $0x18,%eax
80103e46:	89 fb                	mov    %edi,%ebx
80103e48:	c1 e3 10             	shl    $0x10,%ebx
80103e4b:	09 d8                	or     %ebx,%eax
80103e4d:	89 fb                	mov    %edi,%ebx
80103e4f:	c1 e3 08             	shl    $0x8,%ebx
80103e52:	09 d8                	or     %ebx,%eax
80103e54:	09 f8                	or     %edi,%eax
  asm volatile("cld; rep stosl" :
80103e56:	89 d7                	mov    %edx,%edi
80103e58:	fc                   	cld    
80103e59:	f3 ab                	rep stos %eax,%es:(%edi)
}
80103e5b:	eb 05                	jmp    80103e62 <memset+0x41>
  asm volatile("cld; rep stosb" :
80103e5d:	89 d7                	mov    %edx,%edi
80103e5f:	fc                   	cld    
80103e60:	f3 aa                	rep stos %al,%es:(%edi)
  } else
    stosb(dst, c, n);
  return dst;
}
80103e62:	89 d0                	mov    %edx,%eax
80103e64:	5b                   	pop    %ebx
80103e65:	5f                   	pop    %edi
80103e66:	5d                   	pop    %ebp
80103e67:	c3                   	ret    

80103e68 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80103e68:	f3 0f 1e fb          	endbr32 
80103e6c:	55                   	push   %ebp
80103e6d:	89 e5                	mov    %esp,%ebp
80103e6f:	56                   	push   %esi
80103e70:	53                   	push   %ebx
80103e71:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103e74:	8b 55 0c             	mov    0xc(%ebp),%edx
80103e77:	8b 45 10             	mov    0x10(%ebp),%eax
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80103e7a:	8d 70 ff             	lea    -0x1(%eax),%esi
80103e7d:	85 c0                	test   %eax,%eax
80103e7f:	74 1c                	je     80103e9d <memcmp+0x35>
    if(*s1 != *s2)
80103e81:	0f b6 01             	movzbl (%ecx),%eax
80103e84:	0f b6 1a             	movzbl (%edx),%ebx
80103e87:	38 d8                	cmp    %bl,%al
80103e89:	75 0a                	jne    80103e95 <memcmp+0x2d>
      return *s1 - *s2;
    s1++, s2++;
80103e8b:	83 c1 01             	add    $0x1,%ecx
80103e8e:	83 c2 01             	add    $0x1,%edx
  while(n-- > 0){
80103e91:	89 f0                	mov    %esi,%eax
80103e93:	eb e5                	jmp    80103e7a <memcmp+0x12>
      return *s1 - *s2;
80103e95:	0f b6 c0             	movzbl %al,%eax
80103e98:	0f b6 db             	movzbl %bl,%ebx
80103e9b:	29 d8                	sub    %ebx,%eax
  }

  return 0;
}
80103e9d:	5b                   	pop    %ebx
80103e9e:	5e                   	pop    %esi
80103e9f:	5d                   	pop    %ebp
80103ea0:	c3                   	ret    

80103ea1 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80103ea1:	f3 0f 1e fb          	endbr32 
80103ea5:	55                   	push   %ebp
80103ea6:	89 e5                	mov    %esp,%ebp
80103ea8:	56                   	push   %esi
80103ea9:	53                   	push   %ebx
80103eaa:	8b 75 08             	mov    0x8(%ebp),%esi
80103ead:	8b 55 0c             	mov    0xc(%ebp),%edx
80103eb0:	8b 45 10             	mov    0x10(%ebp),%eax
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80103eb3:	39 f2                	cmp    %esi,%edx
80103eb5:	73 3a                	jae    80103ef1 <memmove+0x50>
80103eb7:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
80103eba:	39 f1                	cmp    %esi,%ecx
80103ebc:	76 37                	jbe    80103ef5 <memmove+0x54>
    s += n;
    d += n;
80103ebe:	8d 14 06             	lea    (%esi,%eax,1),%edx
    while(n-- > 0)
80103ec1:	8d 58 ff             	lea    -0x1(%eax),%ebx
80103ec4:	85 c0                	test   %eax,%eax
80103ec6:	74 23                	je     80103eeb <memmove+0x4a>
      *--d = *--s;
80103ec8:	83 e9 01             	sub    $0x1,%ecx
80103ecb:	83 ea 01             	sub    $0x1,%edx
80103ece:	0f b6 01             	movzbl (%ecx),%eax
80103ed1:	88 02                	mov    %al,(%edx)
    while(n-- > 0)
80103ed3:	89 d8                	mov    %ebx,%eax
80103ed5:	eb ea                	jmp    80103ec1 <memmove+0x20>
  } else
    while(n-- > 0)
      *d++ = *s++;
80103ed7:	0f b6 02             	movzbl (%edx),%eax
80103eda:	88 01                	mov    %al,(%ecx)
80103edc:	8d 49 01             	lea    0x1(%ecx),%ecx
80103edf:	8d 52 01             	lea    0x1(%edx),%edx
    while(n-- > 0)
80103ee2:	89 d8                	mov    %ebx,%eax
80103ee4:	8d 58 ff             	lea    -0x1(%eax),%ebx
80103ee7:	85 c0                	test   %eax,%eax
80103ee9:	75 ec                	jne    80103ed7 <memmove+0x36>

  return dst;
}
80103eeb:	89 f0                	mov    %esi,%eax
80103eed:	5b                   	pop    %ebx
80103eee:	5e                   	pop    %esi
80103eef:	5d                   	pop    %ebp
80103ef0:	c3                   	ret    
80103ef1:	89 f1                	mov    %esi,%ecx
80103ef3:	eb ef                	jmp    80103ee4 <memmove+0x43>
80103ef5:	89 f1                	mov    %esi,%ecx
80103ef7:	eb eb                	jmp    80103ee4 <memmove+0x43>

80103ef9 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80103ef9:	f3 0f 1e fb          	endbr32 
80103efd:	55                   	push   %ebp
80103efe:	89 e5                	mov    %esp,%ebp
80103f00:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
80103f03:	ff 75 10             	pushl  0x10(%ebp)
80103f06:	ff 75 0c             	pushl  0xc(%ebp)
80103f09:	ff 75 08             	pushl  0x8(%ebp)
80103f0c:	e8 90 ff ff ff       	call   80103ea1 <memmove>
}
80103f11:	c9                   	leave  
80103f12:	c3                   	ret    

80103f13 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80103f13:	f3 0f 1e fb          	endbr32 
80103f17:	55                   	push   %ebp
80103f18:	89 e5                	mov    %esp,%ebp
80103f1a:	53                   	push   %ebx
80103f1b:	8b 55 08             	mov    0x8(%ebp),%edx
80103f1e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103f21:	8b 45 10             	mov    0x10(%ebp),%eax
  while(n > 0 && *p && *p == *q)
80103f24:	eb 09                	jmp    80103f2f <strncmp+0x1c>
    n--, p++, q++;
80103f26:	83 e8 01             	sub    $0x1,%eax
80103f29:	83 c2 01             	add    $0x1,%edx
80103f2c:	83 c1 01             	add    $0x1,%ecx
  while(n > 0 && *p && *p == *q)
80103f2f:	85 c0                	test   %eax,%eax
80103f31:	74 0b                	je     80103f3e <strncmp+0x2b>
80103f33:	0f b6 1a             	movzbl (%edx),%ebx
80103f36:	84 db                	test   %bl,%bl
80103f38:	74 04                	je     80103f3e <strncmp+0x2b>
80103f3a:	3a 19                	cmp    (%ecx),%bl
80103f3c:	74 e8                	je     80103f26 <strncmp+0x13>
  if(n == 0)
80103f3e:	85 c0                	test   %eax,%eax
80103f40:	74 0b                	je     80103f4d <strncmp+0x3a>
    return 0;
  return (uchar)*p - (uchar)*q;
80103f42:	0f b6 02             	movzbl (%edx),%eax
80103f45:	0f b6 11             	movzbl (%ecx),%edx
80103f48:	29 d0                	sub    %edx,%eax
}
80103f4a:	5b                   	pop    %ebx
80103f4b:	5d                   	pop    %ebp
80103f4c:	c3                   	ret    
    return 0;
80103f4d:	b8 00 00 00 00       	mov    $0x0,%eax
80103f52:	eb f6                	jmp    80103f4a <strncmp+0x37>

80103f54 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80103f54:	f3 0f 1e fb          	endbr32 
80103f58:	55                   	push   %ebp
80103f59:	89 e5                	mov    %esp,%ebp
80103f5b:	57                   	push   %edi
80103f5c:	56                   	push   %esi
80103f5d:	53                   	push   %ebx
80103f5e:	8b 7d 08             	mov    0x8(%ebp),%edi
80103f61:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103f64:	8b 45 10             	mov    0x10(%ebp),%eax
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
80103f67:	89 fa                	mov    %edi,%edx
80103f69:	eb 04                	jmp    80103f6f <strncpy+0x1b>
80103f6b:	89 f1                	mov    %esi,%ecx
80103f6d:	89 da                	mov    %ebx,%edx
80103f6f:	89 c3                	mov    %eax,%ebx
80103f71:	83 e8 01             	sub    $0x1,%eax
80103f74:	85 db                	test   %ebx,%ebx
80103f76:	7e 1b                	jle    80103f93 <strncpy+0x3f>
80103f78:	8d 71 01             	lea    0x1(%ecx),%esi
80103f7b:	8d 5a 01             	lea    0x1(%edx),%ebx
80103f7e:	0f b6 09             	movzbl (%ecx),%ecx
80103f81:	88 0a                	mov    %cl,(%edx)
80103f83:	84 c9                	test   %cl,%cl
80103f85:	75 e4                	jne    80103f6b <strncpy+0x17>
80103f87:	89 da                	mov    %ebx,%edx
80103f89:	eb 08                	jmp    80103f93 <strncpy+0x3f>
    ;
  while(n-- > 0)
    *s++ = 0;
80103f8b:	c6 02 00             	movb   $0x0,(%edx)
  while(n-- > 0)
80103f8e:	89 c8                	mov    %ecx,%eax
    *s++ = 0;
80103f90:	8d 52 01             	lea    0x1(%edx),%edx
  while(n-- > 0)
80103f93:	8d 48 ff             	lea    -0x1(%eax),%ecx
80103f96:	85 c0                	test   %eax,%eax
80103f98:	7f f1                	jg     80103f8b <strncpy+0x37>
  return os;
}
80103f9a:	89 f8                	mov    %edi,%eax
80103f9c:	5b                   	pop    %ebx
80103f9d:	5e                   	pop    %esi
80103f9e:	5f                   	pop    %edi
80103f9f:	5d                   	pop    %ebp
80103fa0:	c3                   	ret    

80103fa1 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80103fa1:	f3 0f 1e fb          	endbr32 
80103fa5:	55                   	push   %ebp
80103fa6:	89 e5                	mov    %esp,%ebp
80103fa8:	57                   	push   %edi
80103fa9:	56                   	push   %esi
80103faa:	53                   	push   %ebx
80103fab:	8b 7d 08             	mov    0x8(%ebp),%edi
80103fae:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103fb1:	8b 45 10             	mov    0x10(%ebp),%eax
  char *os;

  os = s;
  if(n <= 0)
80103fb4:	85 c0                	test   %eax,%eax
80103fb6:	7e 23                	jle    80103fdb <safestrcpy+0x3a>
80103fb8:	89 fa                	mov    %edi,%edx
80103fba:	eb 04                	jmp    80103fc0 <safestrcpy+0x1f>
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
80103fbc:	89 f1                	mov    %esi,%ecx
80103fbe:	89 da                	mov    %ebx,%edx
80103fc0:	83 e8 01             	sub    $0x1,%eax
80103fc3:	85 c0                	test   %eax,%eax
80103fc5:	7e 11                	jle    80103fd8 <safestrcpy+0x37>
80103fc7:	8d 71 01             	lea    0x1(%ecx),%esi
80103fca:	8d 5a 01             	lea    0x1(%edx),%ebx
80103fcd:	0f b6 09             	movzbl (%ecx),%ecx
80103fd0:	88 0a                	mov    %cl,(%edx)
80103fd2:	84 c9                	test   %cl,%cl
80103fd4:	75 e6                	jne    80103fbc <safestrcpy+0x1b>
80103fd6:	89 da                	mov    %ebx,%edx
    ;
  *s = 0;
80103fd8:	c6 02 00             	movb   $0x0,(%edx)
  return os;
}
80103fdb:	89 f8                	mov    %edi,%eax
80103fdd:	5b                   	pop    %ebx
80103fde:	5e                   	pop    %esi
80103fdf:	5f                   	pop    %edi
80103fe0:	5d                   	pop    %ebp
80103fe1:	c3                   	ret    

80103fe2 <strlen>:

int
strlen(const char *s)
{
80103fe2:	f3 0f 1e fb          	endbr32 
80103fe6:	55                   	push   %ebp
80103fe7:	89 e5                	mov    %esp,%ebp
80103fe9:	8b 55 08             	mov    0x8(%ebp),%edx
  int n;

  for(n = 0; s[n]; n++)
80103fec:	b8 00 00 00 00       	mov    $0x0,%eax
80103ff1:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
80103ff5:	74 05                	je     80103ffc <strlen+0x1a>
80103ff7:	83 c0 01             	add    $0x1,%eax
80103ffa:	eb f5                	jmp    80103ff1 <strlen+0xf>
    ;
  return n;
}
80103ffc:	5d                   	pop    %ebp
80103ffd:	c3                   	ret    

80103ffe <swtch>:
# a struct context, and save its address in *old.
# Switch stacks to new and pop previously-saved registers.

.globl swtch
swtch:
  movl 4(%esp), %eax
80103ffe:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80104002:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
80104006:	55                   	push   %ebp
  pushl %ebx
80104007:	53                   	push   %ebx
  pushl %esi
80104008:	56                   	push   %esi
  pushl %edi
80104009:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
8010400a:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
8010400c:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
8010400e:	5f                   	pop    %edi
  popl %esi
8010400f:	5e                   	pop    %esi
  popl %ebx
80104010:	5b                   	pop    %ebx
  popl %ebp
80104011:	5d                   	pop    %ebp
  ret
80104012:	c3                   	ret    

80104013 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
80104013:	f3 0f 1e fb          	endbr32 
80104017:	55                   	push   %ebp
80104018:	89 e5                	mov    %esp,%ebp
8010401a:	53                   	push   %ebx
8010401b:	83 ec 04             	sub    $0x4,%esp
8010401e:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *curproc = myproc();
80104021:	e8 f4 f2 ff ff       	call   8010331a <myproc>

  if(addr >= curproc->sz || addr+4 > curproc->sz)
80104026:	8b 00                	mov    (%eax),%eax
80104028:	39 d8                	cmp    %ebx,%eax
8010402a:	76 19                	jbe    80104045 <fetchint+0x32>
8010402c:	8d 53 04             	lea    0x4(%ebx),%edx
8010402f:	39 d0                	cmp    %edx,%eax
80104031:	72 19                	jb     8010404c <fetchint+0x39>
    return -1;
  *ip = *(int*)(addr);
80104033:	8b 13                	mov    (%ebx),%edx
80104035:	8b 45 0c             	mov    0xc(%ebp),%eax
80104038:	89 10                	mov    %edx,(%eax)
  return 0;
8010403a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010403f:	83 c4 04             	add    $0x4,%esp
80104042:	5b                   	pop    %ebx
80104043:	5d                   	pop    %ebp
80104044:	c3                   	ret    
    return -1;
80104045:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010404a:	eb f3                	jmp    8010403f <fetchint+0x2c>
8010404c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104051:	eb ec                	jmp    8010403f <fetchint+0x2c>

80104053 <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
80104053:	f3 0f 1e fb          	endbr32 
80104057:	55                   	push   %ebp
80104058:	89 e5                	mov    %esp,%ebp
8010405a:	53                   	push   %ebx
8010405b:	83 ec 04             	sub    $0x4,%esp
8010405e:	8b 5d 08             	mov    0x8(%ebp),%ebx
  char *s, *ep;
  struct proc *curproc = myproc();
80104061:	e8 b4 f2 ff ff       	call   8010331a <myproc>

  if(addr >= curproc->sz)
80104066:	39 18                	cmp    %ebx,(%eax)
80104068:	76 26                	jbe    80104090 <fetchstr+0x3d>
    return -1;
  *pp = (char*)addr;
8010406a:	8b 55 0c             	mov    0xc(%ebp),%edx
8010406d:	89 1a                	mov    %ebx,(%edx)
  ep = (char*)curproc->sz;
8010406f:	8b 10                	mov    (%eax),%edx
  for(s = *pp; s < ep; s++){
80104071:	89 d8                	mov    %ebx,%eax
80104073:	39 d0                	cmp    %edx,%eax
80104075:	73 0e                	jae    80104085 <fetchstr+0x32>
    if(*s == 0)
80104077:	80 38 00             	cmpb   $0x0,(%eax)
8010407a:	74 05                	je     80104081 <fetchstr+0x2e>
  for(s = *pp; s < ep; s++){
8010407c:	83 c0 01             	add    $0x1,%eax
8010407f:	eb f2                	jmp    80104073 <fetchstr+0x20>
      return s - *pp;
80104081:	29 d8                	sub    %ebx,%eax
80104083:	eb 05                	jmp    8010408a <fetchstr+0x37>
  }
  return -1;
80104085:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010408a:	83 c4 04             	add    $0x4,%esp
8010408d:	5b                   	pop    %ebx
8010408e:	5d                   	pop    %ebp
8010408f:	c3                   	ret    
    return -1;
80104090:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104095:	eb f3                	jmp    8010408a <fetchstr+0x37>

80104097 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
80104097:	f3 0f 1e fb          	endbr32 
8010409b:	55                   	push   %ebp
8010409c:	89 e5                	mov    %esp,%ebp
8010409e:	83 ec 08             	sub    $0x8,%esp
  return fetchint((myproc()->tf->esp) + 4 + 4*n, ip);
801040a1:	e8 74 f2 ff ff       	call   8010331a <myproc>
801040a6:	8b 50 18             	mov    0x18(%eax),%edx
801040a9:	8b 45 08             	mov    0x8(%ebp),%eax
801040ac:	c1 e0 02             	shl    $0x2,%eax
801040af:	03 42 44             	add    0x44(%edx),%eax
801040b2:	83 ec 08             	sub    $0x8,%esp
801040b5:	ff 75 0c             	pushl  0xc(%ebp)
801040b8:	83 c0 04             	add    $0x4,%eax
801040bb:	50                   	push   %eax
801040bc:	e8 52 ff ff ff       	call   80104013 <fetchint>
}
801040c1:	c9                   	leave  
801040c2:	c3                   	ret    

801040c3 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
801040c3:	f3 0f 1e fb          	endbr32 
801040c7:	55                   	push   %ebp
801040c8:	89 e5                	mov    %esp,%ebp
801040ca:	56                   	push   %esi
801040cb:	53                   	push   %ebx
801040cc:	83 ec 10             	sub    $0x10,%esp
801040cf:	8b 5d 10             	mov    0x10(%ebp),%ebx
  int i;
  struct proc *curproc = myproc();
801040d2:	e8 43 f2 ff ff       	call   8010331a <myproc>
801040d7:	89 c6                	mov    %eax,%esi

  if(argint(n, &i) < 0)
801040d9:	83 ec 08             	sub    $0x8,%esp
801040dc:	8d 45 f4             	lea    -0xc(%ebp),%eax
801040df:	50                   	push   %eax
801040e0:	ff 75 08             	pushl  0x8(%ebp)
801040e3:	e8 af ff ff ff       	call   80104097 <argint>
801040e8:	83 c4 10             	add    $0x10,%esp
801040eb:	85 c0                	test   %eax,%eax
801040ed:	78 24                	js     80104113 <argptr+0x50>
    return -1;
  if(size < 0 || (uint)i >= curproc->sz || (uint)i+size > curproc->sz)
801040ef:	85 db                	test   %ebx,%ebx
801040f1:	78 27                	js     8010411a <argptr+0x57>
801040f3:	8b 16                	mov    (%esi),%edx
801040f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040f8:	39 c2                	cmp    %eax,%edx
801040fa:	76 25                	jbe    80104121 <argptr+0x5e>
801040fc:	01 c3                	add    %eax,%ebx
801040fe:	39 da                	cmp    %ebx,%edx
80104100:	72 26                	jb     80104128 <argptr+0x65>
    return -1;
  *pp = (char*)i;
80104102:	8b 55 0c             	mov    0xc(%ebp),%edx
80104105:	89 02                	mov    %eax,(%edx)
  return 0;
80104107:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010410c:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010410f:	5b                   	pop    %ebx
80104110:	5e                   	pop    %esi
80104111:	5d                   	pop    %ebp
80104112:	c3                   	ret    
    return -1;
80104113:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104118:	eb f2                	jmp    8010410c <argptr+0x49>
    return -1;
8010411a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010411f:	eb eb                	jmp    8010410c <argptr+0x49>
80104121:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104126:	eb e4                	jmp    8010410c <argptr+0x49>
80104128:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010412d:	eb dd                	jmp    8010410c <argptr+0x49>

8010412f <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
8010412f:	f3 0f 1e fb          	endbr32 
80104133:	55                   	push   %ebp
80104134:	89 e5                	mov    %esp,%ebp
80104136:	83 ec 20             	sub    $0x20,%esp
  int addr;
  if(argint(n, &addr) < 0)
80104139:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010413c:	50                   	push   %eax
8010413d:	ff 75 08             	pushl  0x8(%ebp)
80104140:	e8 52 ff ff ff       	call   80104097 <argint>
80104145:	83 c4 10             	add    $0x10,%esp
80104148:	85 c0                	test   %eax,%eax
8010414a:	78 13                	js     8010415f <argstr+0x30>
    return -1;
  return fetchstr(addr, pp);
8010414c:	83 ec 08             	sub    $0x8,%esp
8010414f:	ff 75 0c             	pushl  0xc(%ebp)
80104152:	ff 75 f4             	pushl  -0xc(%ebp)
80104155:	e8 f9 fe ff ff       	call   80104053 <fetchstr>
8010415a:	83 c4 10             	add    $0x10,%esp
}
8010415d:	c9                   	leave  
8010415e:	c3                   	ret    
    return -1;
8010415f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104164:	eb f7                	jmp    8010415d <argstr+0x2e>

80104166 <syscall>:
};
#endif // PRINT_SYSCALLS

void
syscall(void)
{
80104166:	f3 0f 1e fb          	endbr32 
8010416a:	55                   	push   %ebp
8010416b:	89 e5                	mov    %esp,%ebp
8010416d:	53                   	push   %ebx
8010416e:	83 ec 04             	sub    $0x4,%esp
  int num;
  struct proc *curproc = myproc();
80104171:	e8 a4 f1 ff ff       	call   8010331a <myproc>
80104176:	89 c3                	mov    %eax,%ebx

  num = curproc->tf->eax;
80104178:	8b 40 18             	mov    0x18(%eax),%eax
8010417b:	8b 40 1c             	mov    0x1c(%eax),%eax
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
8010417e:	8d 50 ff             	lea    -0x1(%eax),%edx
80104181:	83 fa 16             	cmp    $0x16,%edx
80104184:	77 17                	ja     8010419d <syscall+0x37>
80104186:	8b 14 85 60 6d 10 80 	mov    -0x7fef92a0(,%eax,4),%edx
8010418d:	85 d2                	test   %edx,%edx
8010418f:	74 0c                	je     8010419d <syscall+0x37>
    curproc->tf->eax = syscalls[num]();
80104191:	ff d2                	call   *%edx
80104193:	89 c2                	mov    %eax,%edx
80104195:	8b 43 18             	mov    0x18(%ebx),%eax
80104198:	89 50 1c             	mov    %edx,0x1c(%eax)
8010419b:	eb 1f                	jmp    801041bc <syscall+0x56>
    cprintf("%s -> %d\n",
            syscallnames[num], curproc->tf->eax);
    #endif
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            curproc->pid, curproc->name, num);
8010419d:	8d 53 6c             	lea    0x6c(%ebx),%edx
    cprintf("%d %s: unknown sys call %d\n",
801041a0:	50                   	push   %eax
801041a1:	52                   	push   %edx
801041a2:	ff 73 10             	pushl  0x10(%ebx)
801041a5:	68 25 6d 10 80       	push   $0x80106d25
801041aa:	e8 7a c4 ff ff       	call   80100629 <cprintf>
    curproc->tf->eax = -1;
801041af:	8b 43 18             	mov    0x18(%ebx),%eax
801041b2:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
801041b9:	83 c4 10             	add    $0x10,%esp
  }
}
801041bc:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801041bf:	c9                   	leave  
801041c0:	c3                   	ret    

801041c1 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
801041c1:	55                   	push   %ebp
801041c2:	89 e5                	mov    %esp,%ebp
801041c4:	56                   	push   %esi
801041c5:	53                   	push   %ebx
801041c6:	83 ec 18             	sub    $0x18,%esp
801041c9:	89 d6                	mov    %edx,%esi
801041cb:	89 cb                	mov    %ecx,%ebx
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
801041cd:	8d 55 f4             	lea    -0xc(%ebp),%edx
801041d0:	52                   	push   %edx
801041d1:	50                   	push   %eax
801041d2:	e8 c0 fe ff ff       	call   80104097 <argint>
801041d7:	83 c4 10             	add    $0x10,%esp
801041da:	85 c0                	test   %eax,%eax
801041dc:	78 35                	js     80104213 <argfd+0x52>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
801041de:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
801041e2:	77 28                	ja     8010420c <argfd+0x4b>
801041e4:	e8 31 f1 ff ff       	call   8010331a <myproc>
801041e9:	8b 55 f4             	mov    -0xc(%ebp),%edx
801041ec:	8b 44 90 28          	mov    0x28(%eax,%edx,4),%eax
801041f0:	85 c0                	test   %eax,%eax
801041f2:	74 18                	je     8010420c <argfd+0x4b>
    return -1;
  if(pfd)
801041f4:	85 f6                	test   %esi,%esi
801041f6:	74 02                	je     801041fa <argfd+0x39>
    *pfd = fd;
801041f8:	89 16                	mov    %edx,(%esi)
  if(pf)
801041fa:	85 db                	test   %ebx,%ebx
801041fc:	74 1c                	je     8010421a <argfd+0x59>
    *pf = f;
801041fe:	89 03                	mov    %eax,(%ebx)
  return 0;
80104200:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104205:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104208:	5b                   	pop    %ebx
80104209:	5e                   	pop    %esi
8010420a:	5d                   	pop    %ebp
8010420b:	c3                   	ret    
    return -1;
8010420c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104211:	eb f2                	jmp    80104205 <argfd+0x44>
    return -1;
80104213:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104218:	eb eb                	jmp    80104205 <argfd+0x44>
  return 0;
8010421a:	b8 00 00 00 00       	mov    $0x0,%eax
8010421f:	eb e4                	jmp    80104205 <argfd+0x44>

80104221 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80104221:	55                   	push   %ebp
80104222:	89 e5                	mov    %esp,%ebp
80104224:	53                   	push   %ebx
80104225:	83 ec 04             	sub    $0x4,%esp
80104228:	89 c3                	mov    %eax,%ebx
  int fd;
  struct proc *curproc = myproc();
8010422a:	e8 eb f0 ff ff       	call   8010331a <myproc>
8010422f:	89 c2                	mov    %eax,%edx

  for(fd = 0; fd < NOFILE; fd++){
80104231:	b8 00 00 00 00       	mov    $0x0,%eax
80104236:	83 f8 0f             	cmp    $0xf,%eax
80104239:	7f 12                	jg     8010424d <fdalloc+0x2c>
    if(curproc->ofile[fd] == 0){
8010423b:	83 7c 82 28 00       	cmpl   $0x0,0x28(%edx,%eax,4)
80104240:	74 05                	je     80104247 <fdalloc+0x26>
  for(fd = 0; fd < NOFILE; fd++){
80104242:	83 c0 01             	add    $0x1,%eax
80104245:	eb ef                	jmp    80104236 <fdalloc+0x15>
      curproc->ofile[fd] = f;
80104247:	89 5c 82 28          	mov    %ebx,0x28(%edx,%eax,4)
      return fd;
8010424b:	eb 05                	jmp    80104252 <fdalloc+0x31>
    }
  }
  return -1;
8010424d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104252:	83 c4 04             	add    $0x4,%esp
80104255:	5b                   	pop    %ebx
80104256:	5d                   	pop    %ebp
80104257:	c3                   	ret    

80104258 <isdirempty>:
}

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
80104258:	55                   	push   %ebp
80104259:	89 e5                	mov    %esp,%ebp
8010425b:	56                   	push   %esi
8010425c:	53                   	push   %ebx
8010425d:	83 ec 10             	sub    $0x10,%esp
80104260:	89 c3                	mov    %eax,%ebx
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80104262:	b8 20 00 00 00       	mov    $0x20,%eax
80104267:	89 c6                	mov    %eax,%esi
80104269:	39 43 58             	cmp    %eax,0x58(%ebx)
8010426c:	76 2e                	jbe    8010429c <isdirempty+0x44>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010426e:	6a 10                	push   $0x10
80104270:	50                   	push   %eax
80104271:	8d 45 e8             	lea    -0x18(%ebp),%eax
80104274:	50                   	push   %eax
80104275:	53                   	push   %ebx
80104276:	e8 92 d5 ff ff       	call   8010180d <readi>
8010427b:	83 c4 10             	add    $0x10,%esp
8010427e:	83 f8 10             	cmp    $0x10,%eax
80104281:	75 0c                	jne    8010428f <isdirempty+0x37>
      panic("isdirempty: readi");
    if(de.inum != 0)
80104283:	66 83 7d e8 00       	cmpw   $0x0,-0x18(%ebp)
80104288:	75 1e                	jne    801042a8 <isdirempty+0x50>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
8010428a:	8d 46 10             	lea    0x10(%esi),%eax
8010428d:	eb d8                	jmp    80104267 <isdirempty+0xf>
      panic("isdirempty: readi");
8010428f:	83 ec 0c             	sub    $0xc,%esp
80104292:	68 c0 6d 10 80       	push   $0x80106dc0
80104297:	e8 c0 c0 ff ff       	call   8010035c <panic>
      return 0;
  }
  return 1;
8010429c:	b8 01 00 00 00       	mov    $0x1,%eax
}
801042a1:	8d 65 f8             	lea    -0x8(%ebp),%esp
801042a4:	5b                   	pop    %ebx
801042a5:	5e                   	pop    %esi
801042a6:	5d                   	pop    %ebp
801042a7:	c3                   	ret    
      return 0;
801042a8:	b8 00 00 00 00       	mov    $0x0,%eax
801042ad:	eb f2                	jmp    801042a1 <isdirempty+0x49>

801042af <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
801042af:	55                   	push   %ebp
801042b0:	89 e5                	mov    %esp,%ebp
801042b2:	57                   	push   %edi
801042b3:	56                   	push   %esi
801042b4:	53                   	push   %ebx
801042b5:	83 ec 44             	sub    $0x44,%esp
801042b8:	89 55 c4             	mov    %edx,-0x3c(%ebp)
801042bb:	89 4d c0             	mov    %ecx,-0x40(%ebp)
801042be:	8b 7d 08             	mov    0x8(%ebp),%edi
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
801042c1:	8d 55 d6             	lea    -0x2a(%ebp),%edx
801042c4:	52                   	push   %edx
801042c5:	50                   	push   %eax
801042c6:	e8 dd d9 ff ff       	call   80101ca8 <nameiparent>
801042cb:	89 c6                	mov    %eax,%esi
801042cd:	83 c4 10             	add    $0x10,%esp
801042d0:	85 c0                	test   %eax,%eax
801042d2:	0f 84 35 01 00 00    	je     8010440d <create+0x15e>
    return 0;
  ilock(dp);
801042d8:	83 ec 0c             	sub    $0xc,%esp
801042db:	50                   	push   %eax
801042dc:	e8 26 d3 ff ff       	call   80101607 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
801042e1:	83 c4 0c             	add    $0xc,%esp
801042e4:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801042e7:	50                   	push   %eax
801042e8:	8d 45 d6             	lea    -0x2a(%ebp),%eax
801042eb:	50                   	push   %eax
801042ec:	56                   	push   %esi
801042ed:	e8 64 d7 ff ff       	call   80101a56 <dirlookup>
801042f2:	89 c3                	mov    %eax,%ebx
801042f4:	83 c4 10             	add    $0x10,%esp
801042f7:	85 c0                	test   %eax,%eax
801042f9:	74 3d                	je     80104338 <create+0x89>
    iunlockput(dp);
801042fb:	83 ec 0c             	sub    $0xc,%esp
801042fe:	56                   	push   %esi
801042ff:	e8 b6 d4 ff ff       	call   801017ba <iunlockput>
    ilock(ip);
80104304:	89 1c 24             	mov    %ebx,(%esp)
80104307:	e8 fb d2 ff ff       	call   80101607 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
8010430c:	83 c4 10             	add    $0x10,%esp
8010430f:	66 83 7d c4 02       	cmpw   $0x2,-0x3c(%ebp)
80104314:	75 07                	jne    8010431d <create+0x6e>
80104316:	66 83 7b 50 02       	cmpw   $0x2,0x50(%ebx)
8010431b:	74 11                	je     8010432e <create+0x7f>
      return ip;
    iunlockput(ip);
8010431d:	83 ec 0c             	sub    $0xc,%esp
80104320:	53                   	push   %ebx
80104321:	e8 94 d4 ff ff       	call   801017ba <iunlockput>
    return 0;
80104326:	83 c4 10             	add    $0x10,%esp
80104329:	bb 00 00 00 00       	mov    $0x0,%ebx
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
8010432e:	89 d8                	mov    %ebx,%eax
80104330:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104333:	5b                   	pop    %ebx
80104334:	5e                   	pop    %esi
80104335:	5f                   	pop    %edi
80104336:	5d                   	pop    %ebp
80104337:	c3                   	ret    
  if((ip = ialloc(dp->dev, type)) == 0)
80104338:	83 ec 08             	sub    $0x8,%esp
8010433b:	0f bf 45 c4          	movswl -0x3c(%ebp),%eax
8010433f:	50                   	push   %eax
80104340:	ff 36                	pushl  (%esi)
80104342:	e8 b1 d0 ff ff       	call   801013f8 <ialloc>
80104347:	89 c3                	mov    %eax,%ebx
80104349:	83 c4 10             	add    $0x10,%esp
8010434c:	85 c0                	test   %eax,%eax
8010434e:	74 52                	je     801043a2 <create+0xf3>
  ilock(ip);
80104350:	83 ec 0c             	sub    $0xc,%esp
80104353:	50                   	push   %eax
80104354:	e8 ae d2 ff ff       	call   80101607 <ilock>
  ip->major = major;
80104359:	0f b7 45 c0          	movzwl -0x40(%ebp),%eax
8010435d:	66 89 43 52          	mov    %ax,0x52(%ebx)
  ip->minor = minor;
80104361:	66 89 7b 54          	mov    %di,0x54(%ebx)
  ip->nlink = 1;
80104365:	66 c7 43 56 01 00    	movw   $0x1,0x56(%ebx)
  iupdate(ip);
8010436b:	89 1c 24             	mov    %ebx,(%esp)
8010436e:	e8 2b d1 ff ff       	call   8010149e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
80104373:	83 c4 10             	add    $0x10,%esp
80104376:	66 83 7d c4 01       	cmpw   $0x1,-0x3c(%ebp)
8010437b:	74 32                	je     801043af <create+0x100>
  if(dirlink(dp, name, ip->inum) < 0)
8010437d:	83 ec 04             	sub    $0x4,%esp
80104380:	ff 73 04             	pushl  0x4(%ebx)
80104383:	8d 45 d6             	lea    -0x2a(%ebp),%eax
80104386:	50                   	push   %eax
80104387:	56                   	push   %esi
80104388:	e8 4a d8 ff ff       	call   80101bd7 <dirlink>
8010438d:	83 c4 10             	add    $0x10,%esp
80104390:	85 c0                	test   %eax,%eax
80104392:	78 6c                	js     80104400 <create+0x151>
  iunlockput(dp);
80104394:	83 ec 0c             	sub    $0xc,%esp
80104397:	56                   	push   %esi
80104398:	e8 1d d4 ff ff       	call   801017ba <iunlockput>
  return ip;
8010439d:	83 c4 10             	add    $0x10,%esp
801043a0:	eb 8c                	jmp    8010432e <create+0x7f>
    panic("create: ialloc");
801043a2:	83 ec 0c             	sub    $0xc,%esp
801043a5:	68 d2 6d 10 80       	push   $0x80106dd2
801043aa:	e8 ad bf ff ff       	call   8010035c <panic>
    dp->nlink++;  // for ".."
801043af:	0f b7 46 56          	movzwl 0x56(%esi),%eax
801043b3:	83 c0 01             	add    $0x1,%eax
801043b6:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
801043ba:	83 ec 0c             	sub    $0xc,%esp
801043bd:	56                   	push   %esi
801043be:	e8 db d0 ff ff       	call   8010149e <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
801043c3:	83 c4 0c             	add    $0xc,%esp
801043c6:	ff 73 04             	pushl  0x4(%ebx)
801043c9:	68 e2 6d 10 80       	push   $0x80106de2
801043ce:	53                   	push   %ebx
801043cf:	e8 03 d8 ff ff       	call   80101bd7 <dirlink>
801043d4:	83 c4 10             	add    $0x10,%esp
801043d7:	85 c0                	test   %eax,%eax
801043d9:	78 18                	js     801043f3 <create+0x144>
801043db:	83 ec 04             	sub    $0x4,%esp
801043de:	ff 76 04             	pushl  0x4(%esi)
801043e1:	68 e1 6d 10 80       	push   $0x80106de1
801043e6:	53                   	push   %ebx
801043e7:	e8 eb d7 ff ff       	call   80101bd7 <dirlink>
801043ec:	83 c4 10             	add    $0x10,%esp
801043ef:	85 c0                	test   %eax,%eax
801043f1:	79 8a                	jns    8010437d <create+0xce>
      panic("create dots");
801043f3:	83 ec 0c             	sub    $0xc,%esp
801043f6:	68 e4 6d 10 80       	push   $0x80106de4
801043fb:	e8 5c bf ff ff       	call   8010035c <panic>
    panic("create: dirlink");
80104400:	83 ec 0c             	sub    $0xc,%esp
80104403:	68 f0 6d 10 80       	push   $0x80106df0
80104408:	e8 4f bf ff ff       	call   8010035c <panic>
    return 0;
8010440d:	89 c3                	mov    %eax,%ebx
8010440f:	e9 1a ff ff ff       	jmp    8010432e <create+0x7f>

80104414 <sys_dup>:
{
80104414:	f3 0f 1e fb          	endbr32 
80104418:	55                   	push   %ebp
80104419:	89 e5                	mov    %esp,%ebp
8010441b:	53                   	push   %ebx
8010441c:	83 ec 14             	sub    $0x14,%esp
  if(argfd(0, 0, &f) < 0)
8010441f:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104422:	ba 00 00 00 00       	mov    $0x0,%edx
80104427:	b8 00 00 00 00       	mov    $0x0,%eax
8010442c:	e8 90 fd ff ff       	call   801041c1 <argfd>
80104431:	85 c0                	test   %eax,%eax
80104433:	78 23                	js     80104458 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
80104435:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104438:	e8 e4 fd ff ff       	call   80104221 <fdalloc>
8010443d:	89 c3                	mov    %eax,%ebx
8010443f:	85 c0                	test   %eax,%eax
80104441:	78 1c                	js     8010445f <sys_dup+0x4b>
  filedup(f);
80104443:	83 ec 0c             	sub    $0xc,%esp
80104446:	ff 75 f4             	pushl  -0xc(%ebp)
80104449:	e8 9d c8 ff ff       	call   80100ceb <filedup>
  return fd;
8010444e:	83 c4 10             	add    $0x10,%esp
}
80104451:	89 d8                	mov    %ebx,%eax
80104453:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104456:	c9                   	leave  
80104457:	c3                   	ret    
    return -1;
80104458:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
8010445d:	eb f2                	jmp    80104451 <sys_dup+0x3d>
    return -1;
8010445f:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104464:	eb eb                	jmp    80104451 <sys_dup+0x3d>

80104466 <sys_read>:
{
80104466:	f3 0f 1e fb          	endbr32 
8010446a:	55                   	push   %ebp
8010446b:	89 e5                	mov    %esp,%ebp
8010446d:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80104470:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104473:	ba 00 00 00 00       	mov    $0x0,%edx
80104478:	b8 00 00 00 00       	mov    $0x0,%eax
8010447d:	e8 3f fd ff ff       	call   801041c1 <argfd>
80104482:	85 c0                	test   %eax,%eax
80104484:	78 43                	js     801044c9 <sys_read+0x63>
80104486:	83 ec 08             	sub    $0x8,%esp
80104489:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010448c:	50                   	push   %eax
8010448d:	6a 02                	push   $0x2
8010448f:	e8 03 fc ff ff       	call   80104097 <argint>
80104494:	83 c4 10             	add    $0x10,%esp
80104497:	85 c0                	test   %eax,%eax
80104499:	78 2e                	js     801044c9 <sys_read+0x63>
8010449b:	83 ec 04             	sub    $0x4,%esp
8010449e:	ff 75 f0             	pushl  -0x10(%ebp)
801044a1:	8d 45 ec             	lea    -0x14(%ebp),%eax
801044a4:	50                   	push   %eax
801044a5:	6a 01                	push   $0x1
801044a7:	e8 17 fc ff ff       	call   801040c3 <argptr>
801044ac:	83 c4 10             	add    $0x10,%esp
801044af:	85 c0                	test   %eax,%eax
801044b1:	78 16                	js     801044c9 <sys_read+0x63>
  return fileread(f, p, n);
801044b3:	83 ec 04             	sub    $0x4,%esp
801044b6:	ff 75 f0             	pushl  -0x10(%ebp)
801044b9:	ff 75 ec             	pushl  -0x14(%ebp)
801044bc:	ff 75 f4             	pushl  -0xc(%ebp)
801044bf:	e8 79 c9 ff ff       	call   80100e3d <fileread>
801044c4:	83 c4 10             	add    $0x10,%esp
}
801044c7:	c9                   	leave  
801044c8:	c3                   	ret    
    return -1;
801044c9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801044ce:	eb f7                	jmp    801044c7 <sys_read+0x61>

801044d0 <sys_write>:
{
801044d0:	f3 0f 1e fb          	endbr32 
801044d4:	55                   	push   %ebp
801044d5:	89 e5                	mov    %esp,%ebp
801044d7:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801044da:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801044dd:	ba 00 00 00 00       	mov    $0x0,%edx
801044e2:	b8 00 00 00 00       	mov    $0x0,%eax
801044e7:	e8 d5 fc ff ff       	call   801041c1 <argfd>
801044ec:	85 c0                	test   %eax,%eax
801044ee:	78 43                	js     80104533 <sys_write+0x63>
801044f0:	83 ec 08             	sub    $0x8,%esp
801044f3:	8d 45 f0             	lea    -0x10(%ebp),%eax
801044f6:	50                   	push   %eax
801044f7:	6a 02                	push   $0x2
801044f9:	e8 99 fb ff ff       	call   80104097 <argint>
801044fe:	83 c4 10             	add    $0x10,%esp
80104501:	85 c0                	test   %eax,%eax
80104503:	78 2e                	js     80104533 <sys_write+0x63>
80104505:	83 ec 04             	sub    $0x4,%esp
80104508:	ff 75 f0             	pushl  -0x10(%ebp)
8010450b:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010450e:	50                   	push   %eax
8010450f:	6a 01                	push   $0x1
80104511:	e8 ad fb ff ff       	call   801040c3 <argptr>
80104516:	83 c4 10             	add    $0x10,%esp
80104519:	85 c0                	test   %eax,%eax
8010451b:	78 16                	js     80104533 <sys_write+0x63>
  return filewrite(f, p, n);
8010451d:	83 ec 04             	sub    $0x4,%esp
80104520:	ff 75 f0             	pushl  -0x10(%ebp)
80104523:	ff 75 ec             	pushl  -0x14(%ebp)
80104526:	ff 75 f4             	pushl  -0xc(%ebp)
80104529:	e8 98 c9 ff ff       	call   80100ec6 <filewrite>
8010452e:	83 c4 10             	add    $0x10,%esp
}
80104531:	c9                   	leave  
80104532:	c3                   	ret    
    return -1;
80104533:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104538:	eb f7                	jmp    80104531 <sys_write+0x61>

8010453a <sys_close>:
{
8010453a:	f3 0f 1e fb          	endbr32 
8010453e:	55                   	push   %ebp
8010453f:	89 e5                	mov    %esp,%ebp
80104541:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, &fd, &f) < 0)
80104544:	8d 4d f0             	lea    -0x10(%ebp),%ecx
80104547:	8d 55 f4             	lea    -0xc(%ebp),%edx
8010454a:	b8 00 00 00 00       	mov    $0x0,%eax
8010454f:	e8 6d fc ff ff       	call   801041c1 <argfd>
80104554:	85 c0                	test   %eax,%eax
80104556:	78 25                	js     8010457d <sys_close+0x43>
  myproc()->ofile[fd] = 0;
80104558:	e8 bd ed ff ff       	call   8010331a <myproc>
8010455d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104560:	c7 44 90 28 00 00 00 	movl   $0x0,0x28(%eax,%edx,4)
80104567:	00 
  fileclose(f);
80104568:	83 ec 0c             	sub    $0xc,%esp
8010456b:	ff 75 f0             	pushl  -0x10(%ebp)
8010456e:	e8 c1 c7 ff ff       	call   80100d34 <fileclose>
  return 0;
80104573:	83 c4 10             	add    $0x10,%esp
80104576:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010457b:	c9                   	leave  
8010457c:	c3                   	ret    
    return -1;
8010457d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104582:	eb f7                	jmp    8010457b <sys_close+0x41>

80104584 <sys_fstat>:
{
80104584:	f3 0f 1e fb          	endbr32 
80104588:	55                   	push   %ebp
80104589:	89 e5                	mov    %esp,%ebp
8010458b:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
8010458e:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104591:	ba 00 00 00 00       	mov    $0x0,%edx
80104596:	b8 00 00 00 00       	mov    $0x0,%eax
8010459b:	e8 21 fc ff ff       	call   801041c1 <argfd>
801045a0:	85 c0                	test   %eax,%eax
801045a2:	78 2a                	js     801045ce <sys_fstat+0x4a>
801045a4:	83 ec 04             	sub    $0x4,%esp
801045a7:	6a 14                	push   $0x14
801045a9:	8d 45 f0             	lea    -0x10(%ebp),%eax
801045ac:	50                   	push   %eax
801045ad:	6a 01                	push   $0x1
801045af:	e8 0f fb ff ff       	call   801040c3 <argptr>
801045b4:	83 c4 10             	add    $0x10,%esp
801045b7:	85 c0                	test   %eax,%eax
801045b9:	78 13                	js     801045ce <sys_fstat+0x4a>
  return filestat(f, st);
801045bb:	83 ec 08             	sub    $0x8,%esp
801045be:	ff 75 f0             	pushl  -0x10(%ebp)
801045c1:	ff 75 f4             	pushl  -0xc(%ebp)
801045c4:	e8 29 c8 ff ff       	call   80100df2 <filestat>
801045c9:	83 c4 10             	add    $0x10,%esp
}
801045cc:	c9                   	leave  
801045cd:	c3                   	ret    
    return -1;
801045ce:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045d3:	eb f7                	jmp    801045cc <sys_fstat+0x48>

801045d5 <sys_link>:
{
801045d5:	f3 0f 1e fb          	endbr32 
801045d9:	55                   	push   %ebp
801045da:	89 e5                	mov    %esp,%ebp
801045dc:	56                   	push   %esi
801045dd:	53                   	push   %ebx
801045de:	83 ec 28             	sub    $0x28,%esp
  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
801045e1:	8d 45 e0             	lea    -0x20(%ebp),%eax
801045e4:	50                   	push   %eax
801045e5:	6a 00                	push   $0x0
801045e7:	e8 43 fb ff ff       	call   8010412f <argstr>
801045ec:	83 c4 10             	add    $0x10,%esp
801045ef:	85 c0                	test   %eax,%eax
801045f1:	0f 88 d3 00 00 00    	js     801046ca <sys_link+0xf5>
801045f7:	83 ec 08             	sub    $0x8,%esp
801045fa:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801045fd:	50                   	push   %eax
801045fe:	6a 01                	push   $0x1
80104600:	e8 2a fb ff ff       	call   8010412f <argstr>
80104605:	83 c4 10             	add    $0x10,%esp
80104608:	85 c0                	test   %eax,%eax
8010460a:	0f 88 ba 00 00 00    	js     801046ca <sys_link+0xf5>
  begin_op();
80104610:	e8 77 e2 ff ff       	call   8010288c <begin_op>
  if((ip = namei(old)) == 0){
80104615:	83 ec 0c             	sub    $0xc,%esp
80104618:	ff 75 e0             	pushl  -0x20(%ebp)
8010461b:	e8 6c d6 ff ff       	call   80101c8c <namei>
80104620:	89 c3                	mov    %eax,%ebx
80104622:	83 c4 10             	add    $0x10,%esp
80104625:	85 c0                	test   %eax,%eax
80104627:	0f 84 a4 00 00 00    	je     801046d1 <sys_link+0xfc>
  ilock(ip);
8010462d:	83 ec 0c             	sub    $0xc,%esp
80104630:	50                   	push   %eax
80104631:	e8 d1 cf ff ff       	call   80101607 <ilock>
  if(ip->type == T_DIR){
80104636:	83 c4 10             	add    $0x10,%esp
80104639:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
8010463e:	0f 84 99 00 00 00    	je     801046dd <sys_link+0x108>
  ip->nlink++;
80104644:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
80104648:	83 c0 01             	add    $0x1,%eax
8010464b:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
8010464f:	83 ec 0c             	sub    $0xc,%esp
80104652:	53                   	push   %ebx
80104653:	e8 46 ce ff ff       	call   8010149e <iupdate>
  iunlock(ip);
80104658:	89 1c 24             	mov    %ebx,(%esp)
8010465b:	e8 6d d0 ff ff       	call   801016cd <iunlock>
  if((dp = nameiparent(new, name)) == 0)
80104660:	83 c4 08             	add    $0x8,%esp
80104663:	8d 45 ea             	lea    -0x16(%ebp),%eax
80104666:	50                   	push   %eax
80104667:	ff 75 e4             	pushl  -0x1c(%ebp)
8010466a:	e8 39 d6 ff ff       	call   80101ca8 <nameiparent>
8010466f:	89 c6                	mov    %eax,%esi
80104671:	83 c4 10             	add    $0x10,%esp
80104674:	85 c0                	test   %eax,%eax
80104676:	0f 84 85 00 00 00    	je     80104701 <sys_link+0x12c>
  ilock(dp);
8010467c:	83 ec 0c             	sub    $0xc,%esp
8010467f:	50                   	push   %eax
80104680:	e8 82 cf ff ff       	call   80101607 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
80104685:	83 c4 10             	add    $0x10,%esp
80104688:	8b 03                	mov    (%ebx),%eax
8010468a:	39 06                	cmp    %eax,(%esi)
8010468c:	75 67                	jne    801046f5 <sys_link+0x120>
8010468e:	83 ec 04             	sub    $0x4,%esp
80104691:	ff 73 04             	pushl  0x4(%ebx)
80104694:	8d 45 ea             	lea    -0x16(%ebp),%eax
80104697:	50                   	push   %eax
80104698:	56                   	push   %esi
80104699:	e8 39 d5 ff ff       	call   80101bd7 <dirlink>
8010469e:	83 c4 10             	add    $0x10,%esp
801046a1:	85 c0                	test   %eax,%eax
801046a3:	78 50                	js     801046f5 <sys_link+0x120>
  iunlockput(dp);
801046a5:	83 ec 0c             	sub    $0xc,%esp
801046a8:	56                   	push   %esi
801046a9:	e8 0c d1 ff ff       	call   801017ba <iunlockput>
  iput(ip);
801046ae:	89 1c 24             	mov    %ebx,(%esp)
801046b1:	e8 60 d0 ff ff       	call   80101716 <iput>
  end_op();
801046b6:	e8 4f e2 ff ff       	call   8010290a <end_op>
  return 0;
801046bb:	83 c4 10             	add    $0x10,%esp
801046be:	b8 00 00 00 00       	mov    $0x0,%eax
}
801046c3:	8d 65 f8             	lea    -0x8(%ebp),%esp
801046c6:	5b                   	pop    %ebx
801046c7:	5e                   	pop    %esi
801046c8:	5d                   	pop    %ebp
801046c9:	c3                   	ret    
    return -1;
801046ca:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801046cf:	eb f2                	jmp    801046c3 <sys_link+0xee>
    end_op();
801046d1:	e8 34 e2 ff ff       	call   8010290a <end_op>
    return -1;
801046d6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801046db:	eb e6                	jmp    801046c3 <sys_link+0xee>
    iunlockput(ip);
801046dd:	83 ec 0c             	sub    $0xc,%esp
801046e0:	53                   	push   %ebx
801046e1:	e8 d4 d0 ff ff       	call   801017ba <iunlockput>
    end_op();
801046e6:	e8 1f e2 ff ff       	call   8010290a <end_op>
    return -1;
801046eb:	83 c4 10             	add    $0x10,%esp
801046ee:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801046f3:	eb ce                	jmp    801046c3 <sys_link+0xee>
    iunlockput(dp);
801046f5:	83 ec 0c             	sub    $0xc,%esp
801046f8:	56                   	push   %esi
801046f9:	e8 bc d0 ff ff       	call   801017ba <iunlockput>
    goto bad;
801046fe:	83 c4 10             	add    $0x10,%esp
  ilock(ip);
80104701:	83 ec 0c             	sub    $0xc,%esp
80104704:	53                   	push   %ebx
80104705:	e8 fd ce ff ff       	call   80101607 <ilock>
  ip->nlink--;
8010470a:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
8010470e:	83 e8 01             	sub    $0x1,%eax
80104711:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104715:	89 1c 24             	mov    %ebx,(%esp)
80104718:	e8 81 cd ff ff       	call   8010149e <iupdate>
  iunlockput(ip);
8010471d:	89 1c 24             	mov    %ebx,(%esp)
80104720:	e8 95 d0 ff ff       	call   801017ba <iunlockput>
  end_op();
80104725:	e8 e0 e1 ff ff       	call   8010290a <end_op>
  return -1;
8010472a:	83 c4 10             	add    $0x10,%esp
8010472d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104732:	eb 8f                	jmp    801046c3 <sys_link+0xee>

80104734 <sys_unlink>:
{
80104734:	f3 0f 1e fb          	endbr32 
80104738:	55                   	push   %ebp
80104739:	89 e5                	mov    %esp,%ebp
8010473b:	57                   	push   %edi
8010473c:	56                   	push   %esi
8010473d:	53                   	push   %ebx
8010473e:	83 ec 44             	sub    $0x44,%esp
  if(argstr(0, &path) < 0)
80104741:	8d 45 c4             	lea    -0x3c(%ebp),%eax
80104744:	50                   	push   %eax
80104745:	6a 00                	push   $0x0
80104747:	e8 e3 f9 ff ff       	call   8010412f <argstr>
8010474c:	83 c4 10             	add    $0x10,%esp
8010474f:	85 c0                	test   %eax,%eax
80104751:	0f 88 83 01 00 00    	js     801048da <sys_unlink+0x1a6>
  begin_op();
80104757:	e8 30 e1 ff ff       	call   8010288c <begin_op>
  if((dp = nameiparent(path, name)) == 0){
8010475c:	83 ec 08             	sub    $0x8,%esp
8010475f:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104762:	50                   	push   %eax
80104763:	ff 75 c4             	pushl  -0x3c(%ebp)
80104766:	e8 3d d5 ff ff       	call   80101ca8 <nameiparent>
8010476b:	89 c6                	mov    %eax,%esi
8010476d:	83 c4 10             	add    $0x10,%esp
80104770:	85 c0                	test   %eax,%eax
80104772:	0f 84 ed 00 00 00    	je     80104865 <sys_unlink+0x131>
  ilock(dp);
80104778:	83 ec 0c             	sub    $0xc,%esp
8010477b:	50                   	push   %eax
8010477c:	e8 86 ce ff ff       	call   80101607 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80104781:	83 c4 08             	add    $0x8,%esp
80104784:	68 e2 6d 10 80       	push   $0x80106de2
80104789:	8d 45 ca             	lea    -0x36(%ebp),%eax
8010478c:	50                   	push   %eax
8010478d:	e8 ab d2 ff ff       	call   80101a3d <namecmp>
80104792:	83 c4 10             	add    $0x10,%esp
80104795:	85 c0                	test   %eax,%eax
80104797:	0f 84 fc 00 00 00    	je     80104899 <sys_unlink+0x165>
8010479d:	83 ec 08             	sub    $0x8,%esp
801047a0:	68 e1 6d 10 80       	push   $0x80106de1
801047a5:	8d 45 ca             	lea    -0x36(%ebp),%eax
801047a8:	50                   	push   %eax
801047a9:	e8 8f d2 ff ff       	call   80101a3d <namecmp>
801047ae:	83 c4 10             	add    $0x10,%esp
801047b1:	85 c0                	test   %eax,%eax
801047b3:	0f 84 e0 00 00 00    	je     80104899 <sys_unlink+0x165>
  if((ip = dirlookup(dp, name, &off)) == 0)
801047b9:	83 ec 04             	sub    $0x4,%esp
801047bc:	8d 45 c0             	lea    -0x40(%ebp),%eax
801047bf:	50                   	push   %eax
801047c0:	8d 45 ca             	lea    -0x36(%ebp),%eax
801047c3:	50                   	push   %eax
801047c4:	56                   	push   %esi
801047c5:	e8 8c d2 ff ff       	call   80101a56 <dirlookup>
801047ca:	89 c3                	mov    %eax,%ebx
801047cc:	83 c4 10             	add    $0x10,%esp
801047cf:	85 c0                	test   %eax,%eax
801047d1:	0f 84 c2 00 00 00    	je     80104899 <sys_unlink+0x165>
  ilock(ip);
801047d7:	83 ec 0c             	sub    $0xc,%esp
801047da:	50                   	push   %eax
801047db:	e8 27 ce ff ff       	call   80101607 <ilock>
  if(ip->nlink < 1)
801047e0:	83 c4 10             	add    $0x10,%esp
801047e3:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
801047e8:	0f 8e 83 00 00 00    	jle    80104871 <sys_unlink+0x13d>
  if(ip->type == T_DIR && !isdirempty(ip)){
801047ee:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
801047f3:	0f 84 85 00 00 00    	je     8010487e <sys_unlink+0x14a>
  memset(&de, 0, sizeof(de));
801047f9:	83 ec 04             	sub    $0x4,%esp
801047fc:	6a 10                	push   $0x10
801047fe:	6a 00                	push   $0x0
80104800:	8d 7d d8             	lea    -0x28(%ebp),%edi
80104803:	57                   	push   %edi
80104804:	e8 18 f6 ff ff       	call   80103e21 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80104809:	6a 10                	push   $0x10
8010480b:	ff 75 c0             	pushl  -0x40(%ebp)
8010480e:	57                   	push   %edi
8010480f:	56                   	push   %esi
80104810:	e8 f9 d0 ff ff       	call   8010190e <writei>
80104815:	83 c4 20             	add    $0x20,%esp
80104818:	83 f8 10             	cmp    $0x10,%eax
8010481b:	0f 85 90 00 00 00    	jne    801048b1 <sys_unlink+0x17d>
  if(ip->type == T_DIR){
80104821:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104826:	0f 84 92 00 00 00    	je     801048be <sys_unlink+0x18a>
  iunlockput(dp);
8010482c:	83 ec 0c             	sub    $0xc,%esp
8010482f:	56                   	push   %esi
80104830:	e8 85 cf ff ff       	call   801017ba <iunlockput>
  ip->nlink--;
80104835:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
80104839:	83 e8 01             	sub    $0x1,%eax
8010483c:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104840:	89 1c 24             	mov    %ebx,(%esp)
80104843:	e8 56 cc ff ff       	call   8010149e <iupdate>
  iunlockput(ip);
80104848:	89 1c 24             	mov    %ebx,(%esp)
8010484b:	e8 6a cf ff ff       	call   801017ba <iunlockput>
  end_op();
80104850:	e8 b5 e0 ff ff       	call   8010290a <end_op>
  return 0;
80104855:	83 c4 10             	add    $0x10,%esp
80104858:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010485d:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104860:	5b                   	pop    %ebx
80104861:	5e                   	pop    %esi
80104862:	5f                   	pop    %edi
80104863:	5d                   	pop    %ebp
80104864:	c3                   	ret    
    end_op();
80104865:	e8 a0 e0 ff ff       	call   8010290a <end_op>
    return -1;
8010486a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010486f:	eb ec                	jmp    8010485d <sys_unlink+0x129>
    panic("unlink: nlink < 1");
80104871:	83 ec 0c             	sub    $0xc,%esp
80104874:	68 00 6e 10 80       	push   $0x80106e00
80104879:	e8 de ba ff ff       	call   8010035c <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
8010487e:	89 d8                	mov    %ebx,%eax
80104880:	e8 d3 f9 ff ff       	call   80104258 <isdirempty>
80104885:	85 c0                	test   %eax,%eax
80104887:	0f 85 6c ff ff ff    	jne    801047f9 <sys_unlink+0xc5>
    iunlockput(ip);
8010488d:	83 ec 0c             	sub    $0xc,%esp
80104890:	53                   	push   %ebx
80104891:	e8 24 cf ff ff       	call   801017ba <iunlockput>
    goto bad;
80104896:	83 c4 10             	add    $0x10,%esp
  iunlockput(dp);
80104899:	83 ec 0c             	sub    $0xc,%esp
8010489c:	56                   	push   %esi
8010489d:	e8 18 cf ff ff       	call   801017ba <iunlockput>
  end_op();
801048a2:	e8 63 e0 ff ff       	call   8010290a <end_op>
  return -1;
801048a7:	83 c4 10             	add    $0x10,%esp
801048aa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801048af:	eb ac                	jmp    8010485d <sys_unlink+0x129>
    panic("unlink: writei");
801048b1:	83 ec 0c             	sub    $0xc,%esp
801048b4:	68 12 6e 10 80       	push   $0x80106e12
801048b9:	e8 9e ba ff ff       	call   8010035c <panic>
    dp->nlink--;
801048be:	0f b7 46 56          	movzwl 0x56(%esi),%eax
801048c2:	83 e8 01             	sub    $0x1,%eax
801048c5:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
801048c9:	83 ec 0c             	sub    $0xc,%esp
801048cc:	56                   	push   %esi
801048cd:	e8 cc cb ff ff       	call   8010149e <iupdate>
801048d2:	83 c4 10             	add    $0x10,%esp
801048d5:	e9 52 ff ff ff       	jmp    8010482c <sys_unlink+0xf8>
    return -1;
801048da:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801048df:	e9 79 ff ff ff       	jmp    8010485d <sys_unlink+0x129>

801048e4 <sys_open>:

int
sys_open(void)
{
801048e4:	f3 0f 1e fb          	endbr32 
801048e8:	55                   	push   %ebp
801048e9:	89 e5                	mov    %esp,%ebp
801048eb:	57                   	push   %edi
801048ec:	56                   	push   %esi
801048ed:	53                   	push   %ebx
801048ee:	83 ec 24             	sub    $0x24,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
801048f1:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801048f4:	50                   	push   %eax
801048f5:	6a 00                	push   $0x0
801048f7:	e8 33 f8 ff ff       	call   8010412f <argstr>
801048fc:	83 c4 10             	add    $0x10,%esp
801048ff:	85 c0                	test   %eax,%eax
80104901:	0f 88 a0 00 00 00    	js     801049a7 <sys_open+0xc3>
80104907:	83 ec 08             	sub    $0x8,%esp
8010490a:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010490d:	50                   	push   %eax
8010490e:	6a 01                	push   $0x1
80104910:	e8 82 f7 ff ff       	call   80104097 <argint>
80104915:	83 c4 10             	add    $0x10,%esp
80104918:	85 c0                	test   %eax,%eax
8010491a:	0f 88 87 00 00 00    	js     801049a7 <sys_open+0xc3>
    return -1;

  begin_op();
80104920:	e8 67 df ff ff       	call   8010288c <begin_op>

  if(omode & O_CREATE){
80104925:	f6 45 e1 02          	testb  $0x2,-0x1f(%ebp)
80104929:	0f 84 8b 00 00 00    	je     801049ba <sys_open+0xd6>
    ip = create(path, T_FILE, 0, 0);
8010492f:	83 ec 0c             	sub    $0xc,%esp
80104932:	6a 00                	push   $0x0
80104934:	b9 00 00 00 00       	mov    $0x0,%ecx
80104939:	ba 02 00 00 00       	mov    $0x2,%edx
8010493e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80104941:	e8 69 f9 ff ff       	call   801042af <create>
80104946:	89 c6                	mov    %eax,%esi
    if(ip == 0){
80104948:	83 c4 10             	add    $0x10,%esp
8010494b:	85 c0                	test   %eax,%eax
8010494d:	74 5f                	je     801049ae <sys_open+0xca>
      end_op();
      return -1;
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
8010494f:	e8 32 c3 ff ff       	call   80100c86 <filealloc>
80104954:	89 c3                	mov    %eax,%ebx
80104956:	85 c0                	test   %eax,%eax
80104958:	0f 84 b5 00 00 00    	je     80104a13 <sys_open+0x12f>
8010495e:	e8 be f8 ff ff       	call   80104221 <fdalloc>
80104963:	89 c7                	mov    %eax,%edi
80104965:	85 c0                	test   %eax,%eax
80104967:	0f 88 a6 00 00 00    	js     80104a13 <sys_open+0x12f>
      fileclose(f);
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
8010496d:	83 ec 0c             	sub    $0xc,%esp
80104970:	56                   	push   %esi
80104971:	e8 57 cd ff ff       	call   801016cd <iunlock>
  end_op();
80104976:	e8 8f df ff ff       	call   8010290a <end_op>

  f->type = FD_INODE;
8010497b:	c7 03 02 00 00 00    	movl   $0x2,(%ebx)
  f->ip = ip;
80104981:	89 73 10             	mov    %esi,0x10(%ebx)
  f->off = 0;
80104984:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
  f->readable = !(omode & O_WRONLY);
8010498b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010498e:	83 c4 10             	add    $0x10,%esp
80104991:	a8 01                	test   $0x1,%al
80104993:	0f 94 43 08          	sete   0x8(%ebx)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80104997:	a8 03                	test   $0x3,%al
80104999:	0f 95 43 09          	setne  0x9(%ebx)
  return fd;
}
8010499d:	89 f8                	mov    %edi,%eax
8010499f:	8d 65 f4             	lea    -0xc(%ebp),%esp
801049a2:	5b                   	pop    %ebx
801049a3:	5e                   	pop    %esi
801049a4:	5f                   	pop    %edi
801049a5:	5d                   	pop    %ebp
801049a6:	c3                   	ret    
    return -1;
801049a7:	bf ff ff ff ff       	mov    $0xffffffff,%edi
801049ac:	eb ef                	jmp    8010499d <sys_open+0xb9>
      end_op();
801049ae:	e8 57 df ff ff       	call   8010290a <end_op>
      return -1;
801049b3:	bf ff ff ff ff       	mov    $0xffffffff,%edi
801049b8:	eb e3                	jmp    8010499d <sys_open+0xb9>
    if((ip = namei(path)) == 0){
801049ba:	83 ec 0c             	sub    $0xc,%esp
801049bd:	ff 75 e4             	pushl  -0x1c(%ebp)
801049c0:	e8 c7 d2 ff ff       	call   80101c8c <namei>
801049c5:	89 c6                	mov    %eax,%esi
801049c7:	83 c4 10             	add    $0x10,%esp
801049ca:	85 c0                	test   %eax,%eax
801049cc:	74 39                	je     80104a07 <sys_open+0x123>
    ilock(ip);
801049ce:	83 ec 0c             	sub    $0xc,%esp
801049d1:	50                   	push   %eax
801049d2:	e8 30 cc ff ff       	call   80101607 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
801049d7:	83 c4 10             	add    $0x10,%esp
801049da:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
801049df:	0f 85 6a ff ff ff    	jne    8010494f <sys_open+0x6b>
801049e5:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
801049e9:	0f 84 60 ff ff ff    	je     8010494f <sys_open+0x6b>
      iunlockput(ip);
801049ef:	83 ec 0c             	sub    $0xc,%esp
801049f2:	56                   	push   %esi
801049f3:	e8 c2 cd ff ff       	call   801017ba <iunlockput>
      end_op();
801049f8:	e8 0d df ff ff       	call   8010290a <end_op>
      return -1;
801049fd:	83 c4 10             	add    $0x10,%esp
80104a00:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104a05:	eb 96                	jmp    8010499d <sys_open+0xb9>
      end_op();
80104a07:	e8 fe de ff ff       	call   8010290a <end_op>
      return -1;
80104a0c:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104a11:	eb 8a                	jmp    8010499d <sys_open+0xb9>
    if(f)
80104a13:	85 db                	test   %ebx,%ebx
80104a15:	74 0c                	je     80104a23 <sys_open+0x13f>
      fileclose(f);
80104a17:	83 ec 0c             	sub    $0xc,%esp
80104a1a:	53                   	push   %ebx
80104a1b:	e8 14 c3 ff ff       	call   80100d34 <fileclose>
80104a20:	83 c4 10             	add    $0x10,%esp
    iunlockput(ip);
80104a23:	83 ec 0c             	sub    $0xc,%esp
80104a26:	56                   	push   %esi
80104a27:	e8 8e cd ff ff       	call   801017ba <iunlockput>
    end_op();
80104a2c:	e8 d9 de ff ff       	call   8010290a <end_op>
    return -1;
80104a31:	83 c4 10             	add    $0x10,%esp
80104a34:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104a39:	e9 5f ff ff ff       	jmp    8010499d <sys_open+0xb9>

80104a3e <sys_mkdir>:

int
sys_mkdir(void)
{
80104a3e:	f3 0f 1e fb          	endbr32 
80104a42:	55                   	push   %ebp
80104a43:	89 e5                	mov    %esp,%ebp
80104a45:	83 ec 18             	sub    $0x18,%esp
  char *path;
  struct inode *ip;

  begin_op();
80104a48:	e8 3f de ff ff       	call   8010288c <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80104a4d:	83 ec 08             	sub    $0x8,%esp
80104a50:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104a53:	50                   	push   %eax
80104a54:	6a 00                	push   $0x0
80104a56:	e8 d4 f6 ff ff       	call   8010412f <argstr>
80104a5b:	83 c4 10             	add    $0x10,%esp
80104a5e:	85 c0                	test   %eax,%eax
80104a60:	78 36                	js     80104a98 <sys_mkdir+0x5a>
80104a62:	83 ec 0c             	sub    $0xc,%esp
80104a65:	6a 00                	push   $0x0
80104a67:	b9 00 00 00 00       	mov    $0x0,%ecx
80104a6c:	ba 01 00 00 00       	mov    $0x1,%edx
80104a71:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a74:	e8 36 f8 ff ff       	call   801042af <create>
80104a79:	83 c4 10             	add    $0x10,%esp
80104a7c:	85 c0                	test   %eax,%eax
80104a7e:	74 18                	je     80104a98 <sys_mkdir+0x5a>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104a80:	83 ec 0c             	sub    $0xc,%esp
80104a83:	50                   	push   %eax
80104a84:	e8 31 cd ff ff       	call   801017ba <iunlockput>
  end_op();
80104a89:	e8 7c de ff ff       	call   8010290a <end_op>
  return 0;
80104a8e:	83 c4 10             	add    $0x10,%esp
80104a91:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104a96:	c9                   	leave  
80104a97:	c3                   	ret    
    end_op();
80104a98:	e8 6d de ff ff       	call   8010290a <end_op>
    return -1;
80104a9d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104aa2:	eb f2                	jmp    80104a96 <sys_mkdir+0x58>

80104aa4 <sys_mknod>:

int
sys_mknod(void)
{
80104aa4:	f3 0f 1e fb          	endbr32 
80104aa8:	55                   	push   %ebp
80104aa9:	89 e5                	mov    %esp,%ebp
80104aab:	83 ec 18             	sub    $0x18,%esp
  struct inode *ip;
  char *path;
  int major, minor;

  begin_op();
80104aae:	e8 d9 dd ff ff       	call   8010288c <begin_op>
  if((argstr(0, &path)) < 0 ||
80104ab3:	83 ec 08             	sub    $0x8,%esp
80104ab6:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104ab9:	50                   	push   %eax
80104aba:	6a 00                	push   $0x0
80104abc:	e8 6e f6 ff ff       	call   8010412f <argstr>
80104ac1:	83 c4 10             	add    $0x10,%esp
80104ac4:	85 c0                	test   %eax,%eax
80104ac6:	78 62                	js     80104b2a <sys_mknod+0x86>
     argint(1, &major) < 0 ||
80104ac8:	83 ec 08             	sub    $0x8,%esp
80104acb:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104ace:	50                   	push   %eax
80104acf:	6a 01                	push   $0x1
80104ad1:	e8 c1 f5 ff ff       	call   80104097 <argint>
  if((argstr(0, &path)) < 0 ||
80104ad6:	83 c4 10             	add    $0x10,%esp
80104ad9:	85 c0                	test   %eax,%eax
80104adb:	78 4d                	js     80104b2a <sys_mknod+0x86>
     argint(2, &minor) < 0 ||
80104add:	83 ec 08             	sub    $0x8,%esp
80104ae0:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104ae3:	50                   	push   %eax
80104ae4:	6a 02                	push   $0x2
80104ae6:	e8 ac f5 ff ff       	call   80104097 <argint>
     argint(1, &major) < 0 ||
80104aeb:	83 c4 10             	add    $0x10,%esp
80104aee:	85 c0                	test   %eax,%eax
80104af0:	78 38                	js     80104b2a <sys_mknod+0x86>
     (ip = create(path, T_DEV, major, minor)) == 0){
80104af2:	0f bf 4d f0          	movswl -0x10(%ebp),%ecx
80104af6:	83 ec 0c             	sub    $0xc,%esp
80104af9:	0f bf 45 ec          	movswl -0x14(%ebp),%eax
80104afd:	50                   	push   %eax
80104afe:	ba 03 00 00 00       	mov    $0x3,%edx
80104b03:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b06:	e8 a4 f7 ff ff       	call   801042af <create>
     argint(2, &minor) < 0 ||
80104b0b:	83 c4 10             	add    $0x10,%esp
80104b0e:	85 c0                	test   %eax,%eax
80104b10:	74 18                	je     80104b2a <sys_mknod+0x86>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104b12:	83 ec 0c             	sub    $0xc,%esp
80104b15:	50                   	push   %eax
80104b16:	e8 9f cc ff ff       	call   801017ba <iunlockput>
  end_op();
80104b1b:	e8 ea dd ff ff       	call   8010290a <end_op>
  return 0;
80104b20:	83 c4 10             	add    $0x10,%esp
80104b23:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104b28:	c9                   	leave  
80104b29:	c3                   	ret    
    end_op();
80104b2a:	e8 db dd ff ff       	call   8010290a <end_op>
    return -1;
80104b2f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b34:	eb f2                	jmp    80104b28 <sys_mknod+0x84>

80104b36 <sys_chdir>:

int
sys_chdir(void)
{
80104b36:	f3 0f 1e fb          	endbr32 
80104b3a:	55                   	push   %ebp
80104b3b:	89 e5                	mov    %esp,%ebp
80104b3d:	56                   	push   %esi
80104b3e:	53                   	push   %ebx
80104b3f:	83 ec 10             	sub    $0x10,%esp
  char *path;
  struct inode *ip;
  struct proc *curproc = myproc();
80104b42:	e8 d3 e7 ff ff       	call   8010331a <myproc>
80104b47:	89 c6                	mov    %eax,%esi

  begin_op();
80104b49:	e8 3e dd ff ff       	call   8010288c <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
80104b4e:	83 ec 08             	sub    $0x8,%esp
80104b51:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104b54:	50                   	push   %eax
80104b55:	6a 00                	push   $0x0
80104b57:	e8 d3 f5 ff ff       	call   8010412f <argstr>
80104b5c:	83 c4 10             	add    $0x10,%esp
80104b5f:	85 c0                	test   %eax,%eax
80104b61:	78 52                	js     80104bb5 <sys_chdir+0x7f>
80104b63:	83 ec 0c             	sub    $0xc,%esp
80104b66:	ff 75 f4             	pushl  -0xc(%ebp)
80104b69:	e8 1e d1 ff ff       	call   80101c8c <namei>
80104b6e:	89 c3                	mov    %eax,%ebx
80104b70:	83 c4 10             	add    $0x10,%esp
80104b73:	85 c0                	test   %eax,%eax
80104b75:	74 3e                	je     80104bb5 <sys_chdir+0x7f>
    end_op();
    return -1;
  }
  ilock(ip);
80104b77:	83 ec 0c             	sub    $0xc,%esp
80104b7a:	50                   	push   %eax
80104b7b:	e8 87 ca ff ff       	call   80101607 <ilock>
  if(ip->type != T_DIR){
80104b80:	83 c4 10             	add    $0x10,%esp
80104b83:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104b88:	75 37                	jne    80104bc1 <sys_chdir+0x8b>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104b8a:	83 ec 0c             	sub    $0xc,%esp
80104b8d:	53                   	push   %ebx
80104b8e:	e8 3a cb ff ff       	call   801016cd <iunlock>
  iput(curproc->cwd);
80104b93:	83 c4 04             	add    $0x4,%esp
80104b96:	ff 76 68             	pushl  0x68(%esi)
80104b99:	e8 78 cb ff ff       	call   80101716 <iput>
  end_op();
80104b9e:	e8 67 dd ff ff       	call   8010290a <end_op>
  curproc->cwd = ip;
80104ba3:	89 5e 68             	mov    %ebx,0x68(%esi)
  return 0;
80104ba6:	83 c4 10             	add    $0x10,%esp
80104ba9:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104bae:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104bb1:	5b                   	pop    %ebx
80104bb2:	5e                   	pop    %esi
80104bb3:	5d                   	pop    %ebp
80104bb4:	c3                   	ret    
    end_op();
80104bb5:	e8 50 dd ff ff       	call   8010290a <end_op>
    return -1;
80104bba:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104bbf:	eb ed                	jmp    80104bae <sys_chdir+0x78>
    iunlockput(ip);
80104bc1:	83 ec 0c             	sub    $0xc,%esp
80104bc4:	53                   	push   %ebx
80104bc5:	e8 f0 cb ff ff       	call   801017ba <iunlockput>
    end_op();
80104bca:	e8 3b dd ff ff       	call   8010290a <end_op>
    return -1;
80104bcf:	83 c4 10             	add    $0x10,%esp
80104bd2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104bd7:	eb d5                	jmp    80104bae <sys_chdir+0x78>

80104bd9 <sys_exec>:

int
sys_exec(void)
{
80104bd9:	f3 0f 1e fb          	endbr32 
80104bdd:	55                   	push   %ebp
80104bde:	89 e5                	mov    %esp,%ebp
80104be0:	53                   	push   %ebx
80104be1:	81 ec 9c 00 00 00    	sub    $0x9c,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80104be7:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104bea:	50                   	push   %eax
80104beb:	6a 00                	push   $0x0
80104bed:	e8 3d f5 ff ff       	call   8010412f <argstr>
80104bf2:	83 c4 10             	add    $0x10,%esp
80104bf5:	85 c0                	test   %eax,%eax
80104bf7:	78 38                	js     80104c31 <sys_exec+0x58>
80104bf9:	83 ec 08             	sub    $0x8,%esp
80104bfc:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80104c02:	50                   	push   %eax
80104c03:	6a 01                	push   $0x1
80104c05:	e8 8d f4 ff ff       	call   80104097 <argint>
80104c0a:	83 c4 10             	add    $0x10,%esp
80104c0d:	85 c0                	test   %eax,%eax
80104c0f:	78 20                	js     80104c31 <sys_exec+0x58>
    return -1;
  }
  memset(argv, 0, sizeof(argv));
80104c11:	83 ec 04             	sub    $0x4,%esp
80104c14:	68 80 00 00 00       	push   $0x80
80104c19:	6a 00                	push   $0x0
80104c1b:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104c21:	50                   	push   %eax
80104c22:	e8 fa f1 ff ff       	call   80103e21 <memset>
80104c27:	83 c4 10             	add    $0x10,%esp
  for(i=0;; i++){
80104c2a:	bb 00 00 00 00       	mov    $0x0,%ebx
80104c2f:	eb 2c                	jmp    80104c5d <sys_exec+0x84>
    return -1;
80104c31:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c36:	eb 78                	jmp    80104cb0 <sys_exec+0xd7>
    if(i >= NELEM(argv))
      return -1;
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
      return -1;
    if(uarg == 0){
      argv[i] = 0;
80104c38:	c7 84 9d 74 ff ff ff 	movl   $0x0,-0x8c(%ebp,%ebx,4)
80104c3f:	00 00 00 00 
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
80104c43:	83 ec 08             	sub    $0x8,%esp
80104c46:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104c4c:	50                   	push   %eax
80104c4d:	ff 75 f4             	pushl  -0xc(%ebp)
80104c50:	e8 e6 bc ff ff       	call   8010093b <exec>
80104c55:	83 c4 10             	add    $0x10,%esp
80104c58:	eb 56                	jmp    80104cb0 <sys_exec+0xd7>
  for(i=0;; i++){
80104c5a:	83 c3 01             	add    $0x1,%ebx
    if(i >= NELEM(argv))
80104c5d:	83 fb 1f             	cmp    $0x1f,%ebx
80104c60:	77 49                	ja     80104cab <sys_exec+0xd2>
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80104c62:	83 ec 08             	sub    $0x8,%esp
80104c65:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80104c6b:	50                   	push   %eax
80104c6c:	8b 85 70 ff ff ff    	mov    -0x90(%ebp),%eax
80104c72:	8d 04 98             	lea    (%eax,%ebx,4),%eax
80104c75:	50                   	push   %eax
80104c76:	e8 98 f3 ff ff       	call   80104013 <fetchint>
80104c7b:	83 c4 10             	add    $0x10,%esp
80104c7e:	85 c0                	test   %eax,%eax
80104c80:	78 33                	js     80104cb5 <sys_exec+0xdc>
    if(uarg == 0){
80104c82:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80104c88:	85 c0                	test   %eax,%eax
80104c8a:	74 ac                	je     80104c38 <sys_exec+0x5f>
    if(fetchstr(uarg, &argv[i]) < 0)
80104c8c:	83 ec 08             	sub    $0x8,%esp
80104c8f:	8d 94 9d 74 ff ff ff 	lea    -0x8c(%ebp,%ebx,4),%edx
80104c96:	52                   	push   %edx
80104c97:	50                   	push   %eax
80104c98:	e8 b6 f3 ff ff       	call   80104053 <fetchstr>
80104c9d:	83 c4 10             	add    $0x10,%esp
80104ca0:	85 c0                	test   %eax,%eax
80104ca2:	79 b6                	jns    80104c5a <sys_exec+0x81>
      return -1;
80104ca4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ca9:	eb 05                	jmp    80104cb0 <sys_exec+0xd7>
      return -1;
80104cab:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104cb0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104cb3:	c9                   	leave  
80104cb4:	c3                   	ret    
      return -1;
80104cb5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104cba:	eb f4                	jmp    80104cb0 <sys_exec+0xd7>

80104cbc <sys_pipe>:

int
sys_pipe(void)
{
80104cbc:	f3 0f 1e fb          	endbr32 
80104cc0:	55                   	push   %ebp
80104cc1:	89 e5                	mov    %esp,%ebp
80104cc3:	53                   	push   %ebx
80104cc4:	83 ec 18             	sub    $0x18,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80104cc7:	6a 08                	push   $0x8
80104cc9:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104ccc:	50                   	push   %eax
80104ccd:	6a 00                	push   $0x0
80104ccf:	e8 ef f3 ff ff       	call   801040c3 <argptr>
80104cd4:	83 c4 10             	add    $0x10,%esp
80104cd7:	85 c0                	test   %eax,%eax
80104cd9:	78 79                	js     80104d54 <sys_pipe+0x98>
    return -1;
  if(pipealloc(&rf, &wf) < 0)
80104cdb:	83 ec 08             	sub    $0x8,%esp
80104cde:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104ce1:	50                   	push   %eax
80104ce2:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104ce5:	50                   	push   %eax
80104ce6:	e8 46 e1 ff ff       	call   80102e31 <pipealloc>
80104ceb:	83 c4 10             	add    $0x10,%esp
80104cee:	85 c0                	test   %eax,%eax
80104cf0:	78 69                	js     80104d5b <sys_pipe+0x9f>
    return -1;
  fd0 = -1;
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80104cf2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104cf5:	e8 27 f5 ff ff       	call   80104221 <fdalloc>
80104cfa:	89 c3                	mov    %eax,%ebx
80104cfc:	85 c0                	test   %eax,%eax
80104cfe:	78 21                	js     80104d21 <sys_pipe+0x65>
80104d00:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104d03:	e8 19 f5 ff ff       	call   80104221 <fdalloc>
80104d08:	85 c0                	test   %eax,%eax
80104d0a:	78 15                	js     80104d21 <sys_pipe+0x65>
      myproc()->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  fd[0] = fd0;
80104d0c:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104d0f:	89 1a                	mov    %ebx,(%edx)
  fd[1] = fd1;
80104d11:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104d14:	89 42 04             	mov    %eax,0x4(%edx)
  return 0;
80104d17:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104d1c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104d1f:	c9                   	leave  
80104d20:	c3                   	ret    
    if(fd0 >= 0)
80104d21:	85 db                	test   %ebx,%ebx
80104d23:	79 20                	jns    80104d45 <sys_pipe+0x89>
    fileclose(rf);
80104d25:	83 ec 0c             	sub    $0xc,%esp
80104d28:	ff 75 f0             	pushl  -0x10(%ebp)
80104d2b:	e8 04 c0 ff ff       	call   80100d34 <fileclose>
    fileclose(wf);
80104d30:	83 c4 04             	add    $0x4,%esp
80104d33:	ff 75 ec             	pushl  -0x14(%ebp)
80104d36:	e8 f9 bf ff ff       	call   80100d34 <fileclose>
    return -1;
80104d3b:	83 c4 10             	add    $0x10,%esp
80104d3e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d43:	eb d7                	jmp    80104d1c <sys_pipe+0x60>
      myproc()->ofile[fd0] = 0;
80104d45:	e8 d0 e5 ff ff       	call   8010331a <myproc>
80104d4a:	c7 44 98 28 00 00 00 	movl   $0x0,0x28(%eax,%ebx,4)
80104d51:	00 
80104d52:	eb d1                	jmp    80104d25 <sys_pipe+0x69>
    return -1;
80104d54:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d59:	eb c1                	jmp    80104d1c <sys_pipe+0x60>
    return -1;
80104d5b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d60:	eb ba                	jmp    80104d1c <sys_pipe+0x60>

80104d62 <sys_fork>:
#include "pdx-kernel.h"
#endif // PDX_XV6

int
sys_fork(void)
{
80104d62:	f3 0f 1e fb          	endbr32 
80104d66:	55                   	push   %ebp
80104d67:	89 e5                	mov    %esp,%ebp
80104d69:	83 ec 08             	sub    $0x8,%esp
  return fork();
80104d6c:	e8 2c e7 ff ff       	call   8010349d <fork>
}
80104d71:	c9                   	leave  
80104d72:	c3                   	ret    

80104d73 <sys_exit>:

int
sys_exit(void)
{
80104d73:	f3 0f 1e fb          	endbr32 
80104d77:	55                   	push   %ebp
80104d78:	89 e5                	mov    %esp,%ebp
80104d7a:	83 ec 08             	sub    $0x8,%esp
  exit();
80104d7d:	e8 6f e9 ff ff       	call   801036f1 <exit>
  return 0;  // not reached
}
80104d82:	b8 00 00 00 00       	mov    $0x0,%eax
80104d87:	c9                   	leave  
80104d88:	c3                   	ret    

80104d89 <sys_wait>:

int
sys_wait(void)
{
80104d89:	f3 0f 1e fb          	endbr32 
80104d8d:	55                   	push   %ebp
80104d8e:	89 e5                	mov    %esp,%ebp
80104d90:	83 ec 08             	sub    $0x8,%esp
  return wait();
80104d93:	e8 fc ea ff ff       	call   80103894 <wait>
}
80104d98:	c9                   	leave  
80104d99:	c3                   	ret    

80104d9a <sys_kill>:

int
sys_kill(void)
{
80104d9a:	f3 0f 1e fb          	endbr32 
80104d9e:	55                   	push   %ebp
80104d9f:	89 e5                	mov    %esp,%ebp
80104da1:	83 ec 20             	sub    $0x20,%esp
  int pid;

  if(argint(0, &pid) < 0)
80104da4:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104da7:	50                   	push   %eax
80104da8:	6a 00                	push   $0x0
80104daa:	e8 e8 f2 ff ff       	call   80104097 <argint>
80104daf:	83 c4 10             	add    $0x10,%esp
80104db2:	85 c0                	test   %eax,%eax
80104db4:	78 10                	js     80104dc6 <sys_kill+0x2c>
    return -1;
  return kill(pid);
80104db6:	83 ec 0c             	sub    $0xc,%esp
80104db9:	ff 75 f4             	pushl  -0xc(%ebp)
80104dbc:	e8 d8 eb ff ff       	call   80103999 <kill>
80104dc1:	83 c4 10             	add    $0x10,%esp
}
80104dc4:	c9                   	leave  
80104dc5:	c3                   	ret    
    return -1;
80104dc6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104dcb:	eb f7                	jmp    80104dc4 <sys_kill+0x2a>

80104dcd <sys_getpid>:

int
sys_getpid(void)
{
80104dcd:	f3 0f 1e fb          	endbr32 
80104dd1:	55                   	push   %ebp
80104dd2:	89 e5                	mov    %esp,%ebp
80104dd4:	83 ec 08             	sub    $0x8,%esp
  return myproc()->pid;
80104dd7:	e8 3e e5 ff ff       	call   8010331a <myproc>
80104ddc:	8b 40 10             	mov    0x10(%eax),%eax
}
80104ddf:	c9                   	leave  
80104de0:	c3                   	ret    

80104de1 <sys_sbrk>:

int
sys_sbrk(void)
{
80104de1:	f3 0f 1e fb          	endbr32 
80104de5:	55                   	push   %ebp
80104de6:	89 e5                	mov    %esp,%ebp
80104de8:	53                   	push   %ebx
80104de9:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80104dec:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104def:	50                   	push   %eax
80104df0:	6a 00                	push   $0x0
80104df2:	e8 a0 f2 ff ff       	call   80104097 <argint>
80104df7:	83 c4 10             	add    $0x10,%esp
80104dfa:	85 c0                	test   %eax,%eax
80104dfc:	78 20                	js     80104e1e <sys_sbrk+0x3d>
    return -1;
  addr = myproc()->sz;
80104dfe:	e8 17 e5 ff ff       	call   8010331a <myproc>
80104e03:	8b 18                	mov    (%eax),%ebx
  if(growproc(n) < 0)
80104e05:	83 ec 0c             	sub    $0xc,%esp
80104e08:	ff 75 f4             	pushl  -0xc(%ebp)
80104e0b:	e8 1e e6 ff ff       	call   8010342e <growproc>
80104e10:	83 c4 10             	add    $0x10,%esp
80104e13:	85 c0                	test   %eax,%eax
80104e15:	78 0e                	js     80104e25 <sys_sbrk+0x44>
    return -1;
  return addr;
}
80104e17:	89 d8                	mov    %ebx,%eax
80104e19:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104e1c:	c9                   	leave  
80104e1d:	c3                   	ret    
    return -1;
80104e1e:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104e23:	eb f2                	jmp    80104e17 <sys_sbrk+0x36>
    return -1;
80104e25:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104e2a:	eb eb                	jmp    80104e17 <sys_sbrk+0x36>

80104e2c <sys_sleep>:

int
sys_sleep(void)
{
80104e2c:	f3 0f 1e fb          	endbr32 
80104e30:	55                   	push   %ebp
80104e31:	89 e5                	mov    %esp,%ebp
80104e33:	53                   	push   %ebx
80104e34:	83 ec 1c             	sub    $0x1c,%esp
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
80104e37:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104e3a:	50                   	push   %eax
80104e3b:	6a 00                	push   $0x0
80104e3d:	e8 55 f2 ff ff       	call   80104097 <argint>
80104e42:	83 c4 10             	add    $0x10,%esp
80104e45:	85 c0                	test   %eax,%eax
80104e47:	78 3b                	js     80104e84 <sys_sleep+0x58>
    return -1;
  ticks0 = ticks;
80104e49:	8b 1d 80 55 11 80    	mov    0x80115580,%ebx
  while(ticks - ticks0 < n){
80104e4f:	a1 80 55 11 80       	mov    0x80115580,%eax
80104e54:	29 d8                	sub    %ebx,%eax
80104e56:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104e59:	73 1f                	jae    80104e7a <sys_sleep+0x4e>
    if(myproc()->killed){
80104e5b:	e8 ba e4 ff ff       	call   8010331a <myproc>
80104e60:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104e64:	75 25                	jne    80104e8b <sys_sleep+0x5f>
      return -1;
    }
    sleep(&ticks, (struct spinlock *)0);
80104e66:	83 ec 08             	sub    $0x8,%esp
80104e69:	6a 00                	push   $0x0
80104e6b:	68 80 55 11 80       	push   $0x80115580
80104e70:	e8 8b e9 ff ff       	call   80103800 <sleep>
80104e75:	83 c4 10             	add    $0x10,%esp
80104e78:	eb d5                	jmp    80104e4f <sys_sleep+0x23>
  }
  return 0;
80104e7a:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104e7f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104e82:	c9                   	leave  
80104e83:	c3                   	ret    
    return -1;
80104e84:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e89:	eb f4                	jmp    80104e7f <sys_sleep+0x53>
      return -1;
80104e8b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e90:	eb ed                	jmp    80104e7f <sys_sleep+0x53>

80104e92 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80104e92:	f3 0f 1e fb          	endbr32 
  uint xticks;

  xticks = ticks;
  return xticks;
}
80104e96:	a1 80 55 11 80       	mov    0x80115580,%eax
80104e9b:	c3                   	ret    

80104e9c <sys_halt>:

#ifdef PDX_XV6
// shutdown QEMU
int
sys_halt(void)
{
80104e9c:	f3 0f 1e fb          	endbr32 
80104ea0:	55                   	push   %ebp
80104ea1:	89 e5                	mov    %esp,%ebp
80104ea3:	83 ec 08             	sub    $0x8,%esp
  do_shutdown();  // never returns
80104ea6:	e8 ae b8 ff ff       	call   80100759 <do_shutdown>
  return 0;
}
80104eab:	b8 00 00 00 00       	mov    $0x0,%eax
80104eb0:	c9                   	leave  
80104eb1:	c3                   	ret    

80104eb2 <sys_date>:
#endif // PDX_XV6

#ifdef CS333_P1
int
sys_date(void)
{
80104eb2:	f3 0f 1e fb          	endbr32 
80104eb6:	55                   	push   %ebp
80104eb7:	89 e5                	mov    %esp,%ebp
80104eb9:	83 ec 1c             	sub    $0x1c,%esp
  struct rtcdate *d;
  if(argptr(0, (void*)&d, sizeof(struct rtcdate)) < 0)
80104ebc:	6a 18                	push   $0x18
80104ebe:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104ec1:	50                   	push   %eax
80104ec2:	6a 00                	push   $0x0
80104ec4:	e8 fa f1 ff ff       	call   801040c3 <argptr>
80104ec9:	83 c4 10             	add    $0x10,%esp
80104ecc:	85 c0                	test   %eax,%eax
80104ece:	78 15                	js     80104ee5 <sys_date+0x33>
    return -1;
  cmostime(d);
80104ed0:	83 ec 0c             	sub    $0xc,%esp
80104ed3:	ff 75 f4             	pushl  -0xc(%ebp)
80104ed6:	e8 5e d6 ff ff       	call   80102539 <cmostime>
  return 0;
80104edb:	83 c4 10             	add    $0x10,%esp
80104ede:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104ee3:	c9                   	leave  
80104ee4:	c3                   	ret    
    return -1;
80104ee5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104eea:	eb f7                	jmp    80104ee3 <sys_date+0x31>

80104eec <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80104eec:	1e                   	push   %ds
  pushl %es
80104eed:	06                   	push   %es
  pushl %fs
80104eee:	0f a0                	push   %fs
  pushl %gs
80104ef0:	0f a8                	push   %gs
  pushal
80104ef2:	60                   	pusha  
  
  # Set up data segments.
  movw $(SEG_KDATA<<3), %ax
80104ef3:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80104ef7:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80104ef9:	8e c0                	mov    %eax,%es

  # Call trap(tf), where tf=%esp
  pushl %esp
80104efb:	54                   	push   %esp
  call trap
80104efc:	e8 cf 00 00 00       	call   80104fd0 <trap>
  addl $4, %esp
80104f01:	83 c4 04             	add    $0x4,%esp

80104f04 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80104f04:	61                   	popa   
  popl %gs
80104f05:	0f a9                	pop    %gs
  popl %fs
80104f07:	0f a1                	pop    %fs
  popl %es
80104f09:	07                   	pop    %es
  popl %ds
80104f0a:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80104f0b:	83 c4 08             	add    $0x8,%esp
  iret
80104f0e:	cf                   	iret   

80104f0f <tvinit>:
uint ticks;
#endif // PDX_XV6

void
tvinit(void)
{
80104f0f:	f3 0f 1e fb          	endbr32 
  int i;

  for(i = 0; i < 256; i++)
80104f13:	b8 00 00 00 00       	mov    $0x0,%eax
80104f18:	3d ff 00 00 00       	cmp    $0xff,%eax
80104f1d:	7f 4c                	jg     80104f6b <tvinit+0x5c>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80104f1f:	8b 0c 85 08 a0 10 80 	mov    -0x7fef5ff8(,%eax,4),%ecx
80104f26:	66 89 0c c5 80 4d 11 	mov    %cx,-0x7feeb280(,%eax,8)
80104f2d:	80 
80104f2e:	66 c7 04 c5 82 4d 11 	movw   $0x8,-0x7feeb27e(,%eax,8)
80104f35:	80 08 00 
80104f38:	c6 04 c5 84 4d 11 80 	movb   $0x0,-0x7feeb27c(,%eax,8)
80104f3f:	00 
80104f40:	0f b6 14 c5 85 4d 11 	movzbl -0x7feeb27b(,%eax,8),%edx
80104f47:	80 
80104f48:	83 e2 f0             	and    $0xfffffff0,%edx
80104f4b:	83 ca 0e             	or     $0xe,%edx
80104f4e:	83 e2 8f             	and    $0xffffff8f,%edx
80104f51:	83 ca 80             	or     $0xffffff80,%edx
80104f54:	88 14 c5 85 4d 11 80 	mov    %dl,-0x7feeb27b(,%eax,8)
80104f5b:	c1 e9 10             	shr    $0x10,%ecx
80104f5e:	66 89 0c c5 86 4d 11 	mov    %cx,-0x7feeb27a(,%eax,8)
80104f65:	80 
  for(i = 0; i < 256; i++)
80104f66:	83 c0 01             	add    $0x1,%eax
80104f69:	eb ad                	jmp    80104f18 <tvinit+0x9>
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80104f6b:	8b 15 08 a1 10 80    	mov    0x8010a108,%edx
80104f71:	66 89 15 80 4f 11 80 	mov    %dx,0x80114f80
80104f78:	66 c7 05 82 4f 11 80 	movw   $0x8,0x80114f82
80104f7f:	08 00 
80104f81:	c6 05 84 4f 11 80 00 	movb   $0x0,0x80114f84
80104f88:	0f b6 05 85 4f 11 80 	movzbl 0x80114f85,%eax
80104f8f:	83 c8 0f             	or     $0xf,%eax
80104f92:	83 e0 ef             	and    $0xffffffef,%eax
80104f95:	83 c8 e0             	or     $0xffffffe0,%eax
80104f98:	a2 85 4f 11 80       	mov    %al,0x80114f85
80104f9d:	c1 ea 10             	shr    $0x10,%edx
80104fa0:	66 89 15 86 4f 11 80 	mov    %dx,0x80114f86

#ifndef PDX_XV6
  initlock(&tickslock, "time");
#endif // PDX_XV6
}
80104fa7:	c3                   	ret    

80104fa8 <idtinit>:

void
idtinit(void)
{
80104fa8:	f3 0f 1e fb          	endbr32 
80104fac:	55                   	push   %ebp
80104fad:	89 e5                	mov    %esp,%ebp
80104faf:	83 ec 10             	sub    $0x10,%esp
  pd[0] = size-1;
80104fb2:	66 c7 45 fa ff 07    	movw   $0x7ff,-0x6(%ebp)
  pd[1] = (uint)p;
80104fb8:	b8 80 4d 11 80       	mov    $0x80114d80,%eax
80104fbd:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80104fc1:	c1 e8 10             	shr    $0x10,%eax
80104fc4:	66 89 45 fe          	mov    %ax,-0x2(%ebp)
  asm volatile("lidt (%0)" : : "r" (pd));
80104fc8:	8d 45 fa             	lea    -0x6(%ebp),%eax
80104fcb:	0f 01 18             	lidtl  (%eax)
  lidt(idt, sizeof(idt));
}
80104fce:	c9                   	leave  
80104fcf:	c3                   	ret    

80104fd0 <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
80104fd0:	f3 0f 1e fb          	endbr32 
80104fd4:	55                   	push   %ebp
80104fd5:	89 e5                	mov    %esp,%ebp
80104fd7:	57                   	push   %edi
80104fd8:	56                   	push   %esi
80104fd9:	53                   	push   %ebx
80104fda:	83 ec 1c             	sub    $0x1c,%esp
80104fdd:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(tf->trapno == T_SYSCALL){
80104fe0:	8b 43 30             	mov    0x30(%ebx),%eax
80104fe3:	83 f8 40             	cmp    $0x40,%eax
80104fe6:	74 14                	je     80104ffc <trap+0x2c>
    if(myproc()->killed)
      exit();
    return;
  }

  switch(tf->trapno){
80104fe8:	83 e8 20             	sub    $0x20,%eax
80104feb:	83 f8 1f             	cmp    $0x1f,%eax
80104fee:	0f 87 23 01 00 00    	ja     80105117 <trap+0x147>
80104ff4:	3e ff 24 85 c4 6e 10 	notrack jmp *-0x7fef913c(,%eax,4)
80104ffb:	80 
    if(myproc()->killed)
80104ffc:	e8 19 e3 ff ff       	call   8010331a <myproc>
80105001:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80105005:	75 1f                	jne    80105026 <trap+0x56>
    myproc()->tf = tf;
80105007:	e8 0e e3 ff ff       	call   8010331a <myproc>
8010500c:	89 58 18             	mov    %ebx,0x18(%eax)
    syscall();
8010500f:	e8 52 f1 ff ff       	call   80104166 <syscall>
    if(myproc()->killed)
80105014:	e8 01 e3 ff ff       	call   8010331a <myproc>
80105019:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
8010501d:	74 7e                	je     8010509d <trap+0xcd>
      exit();
8010501f:	e8 cd e6 ff ff       	call   801036f1 <exit>
    return;
80105024:	eb 77                	jmp    8010509d <trap+0xcd>
      exit();
80105026:	e8 c6 e6 ff ff       	call   801036f1 <exit>
8010502b:	eb da                	jmp    80105007 <trap+0x37>
  case T_IRQ0 + IRQ_TIMER:
    if(cpuid() == 0){
8010502d:	e8 c9 e2 ff ff       	call   801032fb <cpuid>
80105032:	85 c0                	test   %eax,%eax
80105034:	74 6f                	je     801050a5 <trap+0xd5>
      ticks++;
      wakeup(&ticks);
      release(&tickslock);
#endif // PDX_XV6
    }
    lapiceoi();
80105036:	e8 35 d4 ff ff       	call   80102470 <lapiceoi>
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running
  // until it gets to the regular system call return.)
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
8010503b:	e8 da e2 ff ff       	call   8010331a <myproc>
80105040:	85 c0                	test   %eax,%eax
80105042:	74 1c                	je     80105060 <trap+0x90>
80105044:	e8 d1 e2 ff ff       	call   8010331a <myproc>
80105049:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
8010504d:	74 11                	je     80105060 <trap+0x90>
8010504f:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
80105053:	83 e0 03             	and    $0x3,%eax
80105056:	66 83 f8 03          	cmp    $0x3,%ax
8010505a:	0f 84 4a 01 00 00    	je     801051aa <trap+0x1da>
    exit();

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(myproc() && myproc()->state == RUNNING &&
80105060:	e8 b5 e2 ff ff       	call   8010331a <myproc>
80105065:	85 c0                	test   %eax,%eax
80105067:	74 0f                	je     80105078 <trap+0xa8>
80105069:	e8 ac e2 ff ff       	call   8010331a <myproc>
8010506e:	83 78 0c 04          	cmpl   $0x4,0xc(%eax)
80105072:	0f 84 3c 01 00 00    	je     801051b4 <trap+0x1e4>
    tf->trapno == T_IRQ0+IRQ_TIMER)
#endif // PDX_XV6
    yield();

  // Check if the process has been killed since we yielded
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
80105078:	e8 9d e2 ff ff       	call   8010331a <myproc>
8010507d:	85 c0                	test   %eax,%eax
8010507f:	74 1c                	je     8010509d <trap+0xcd>
80105081:	e8 94 e2 ff ff       	call   8010331a <myproc>
80105086:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
8010508a:	74 11                	je     8010509d <trap+0xcd>
8010508c:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
80105090:	83 e0 03             	and    $0x3,%eax
80105093:	66 83 f8 03          	cmp    $0x3,%ax
80105097:	0f 84 4a 01 00 00    	je     801051e7 <trap+0x217>
    exit();
}
8010509d:	8d 65 f4             	lea    -0xc(%ebp),%esp
801050a0:	5b                   	pop    %ebx
801050a1:	5e                   	pop    %esi
801050a2:	5f                   	pop    %edi
801050a3:	5d                   	pop    %ebp
801050a4:	c3                   	ret    
// atom_inc() necessary for removal of tickslock
// other atomic ops added for completeness
static inline void
atom_inc(volatile int *num)
{
  asm volatile ( "lock incl %0" : "=m" (*num));
801050a5:	f0 ff 05 80 55 11 80 	lock incl 0x80115580
      wakeup(&ticks);
801050ac:	83 ec 0c             	sub    $0xc,%esp
801050af:	68 80 55 11 80       	push   $0x80115580
801050b4:	e8 b3 e8 ff ff       	call   8010396c <wakeup>
801050b9:	83 c4 10             	add    $0x10,%esp
801050bc:	e9 75 ff ff ff       	jmp    80105036 <trap+0x66>
    ideintr();
801050c1:	e8 63 cd ff ff       	call   80101e29 <ideintr>
    lapiceoi();
801050c6:	e8 a5 d3 ff ff       	call   80102470 <lapiceoi>
    break;
801050cb:	e9 6b ff ff ff       	jmp    8010503b <trap+0x6b>
    kbdintr();
801050d0:	e8 d8 d1 ff ff       	call   801022ad <kbdintr>
    lapiceoi();
801050d5:	e8 96 d3 ff ff       	call   80102470 <lapiceoi>
    break;
801050da:	e9 5c ff ff ff       	jmp    8010503b <trap+0x6b>
    uartintr();
801050df:	e8 29 02 00 00       	call   8010530d <uartintr>
    lapiceoi();
801050e4:	e8 87 d3 ff ff       	call   80102470 <lapiceoi>
    break;
801050e9:	e9 4d ff ff ff       	jmp    8010503b <trap+0x6b>
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801050ee:	8b 7b 38             	mov    0x38(%ebx),%edi
            cpuid(), tf->cs, tf->eip);
801050f1:	0f b7 73 3c          	movzwl 0x3c(%ebx),%esi
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801050f5:	e8 01 e2 ff ff       	call   801032fb <cpuid>
801050fa:	57                   	push   %edi
801050fb:	0f b7 f6             	movzwl %si,%esi
801050fe:	56                   	push   %esi
801050ff:	50                   	push   %eax
80105100:	68 24 6e 10 80       	push   $0x80106e24
80105105:	e8 1f b5 ff ff       	call   80100629 <cprintf>
    lapiceoi();
8010510a:	e8 61 d3 ff ff       	call   80102470 <lapiceoi>
    break;
8010510f:	83 c4 10             	add    $0x10,%esp
80105112:	e9 24 ff ff ff       	jmp    8010503b <trap+0x6b>
    if(myproc() == 0 || (tf->cs&3) == 0){
80105117:	e8 fe e1 ff ff       	call   8010331a <myproc>
8010511c:	85 c0                	test   %eax,%eax
8010511e:	74 5f                	je     8010517f <trap+0x1af>
80105120:	f6 43 3c 03          	testb  $0x3,0x3c(%ebx)
80105124:	74 59                	je     8010517f <trap+0x1af>

static inline uint
rcr2(void)
{
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
80105126:	0f 20 d7             	mov    %cr2,%edi
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80105129:	8b 43 38             	mov    0x38(%ebx),%eax
8010512c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010512f:	e8 c7 e1 ff ff       	call   801032fb <cpuid>
80105134:	89 45 e0             	mov    %eax,-0x20(%ebp)
80105137:	8b 4b 34             	mov    0x34(%ebx),%ecx
8010513a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
8010513d:	8b 73 30             	mov    0x30(%ebx),%esi
            myproc()->pid, myproc()->name, tf->trapno,
80105140:	e8 d5 e1 ff ff       	call   8010331a <myproc>
80105145:	8d 50 6c             	lea    0x6c(%eax),%edx
80105148:	89 55 d8             	mov    %edx,-0x28(%ebp)
8010514b:	e8 ca e1 ff ff       	call   8010331a <myproc>
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80105150:	57                   	push   %edi
80105151:	ff 75 e4             	pushl  -0x1c(%ebp)
80105154:	ff 75 e0             	pushl  -0x20(%ebp)
80105157:	ff 75 dc             	pushl  -0x24(%ebp)
8010515a:	56                   	push   %esi
8010515b:	ff 75 d8             	pushl  -0x28(%ebp)
8010515e:	ff 70 10             	pushl  0x10(%eax)
80105161:	68 7c 6e 10 80       	push   $0x80106e7c
80105166:	e8 be b4 ff ff       	call   80100629 <cprintf>
    myproc()->killed = 1;
8010516b:	83 c4 20             	add    $0x20,%esp
8010516e:	e8 a7 e1 ff ff       	call   8010331a <myproc>
80105173:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
8010517a:	e9 bc fe ff ff       	jmp    8010503b <trap+0x6b>
8010517f:	0f 20 d7             	mov    %cr2,%edi
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80105182:	8b 73 38             	mov    0x38(%ebx),%esi
80105185:	e8 71 e1 ff ff       	call   801032fb <cpuid>
8010518a:	83 ec 0c             	sub    $0xc,%esp
8010518d:	57                   	push   %edi
8010518e:	56                   	push   %esi
8010518f:	50                   	push   %eax
80105190:	ff 73 30             	pushl  0x30(%ebx)
80105193:	68 48 6e 10 80       	push   $0x80106e48
80105198:	e8 8c b4 ff ff       	call   80100629 <cprintf>
      panic("trap");
8010519d:	83 c4 14             	add    $0x14,%esp
801051a0:	68 bf 6e 10 80       	push   $0x80106ebf
801051a5:	e8 b2 b1 ff ff       	call   8010035c <panic>
    exit();
801051aa:	e8 42 e5 ff ff       	call   801036f1 <exit>
801051af:	e9 ac fe ff ff       	jmp    80105060 <trap+0x90>
  if(myproc() && myproc()->state == RUNNING &&
801051b4:	83 7b 30 20          	cmpl   $0x20,0x30(%ebx)
801051b8:	0f 85 ba fe ff ff    	jne    80105078 <trap+0xa8>
    tf->trapno == T_IRQ0+IRQ_TIMER && ticks%SCHED_INTERVAL==0)
801051be:	8b 0d 80 55 11 80    	mov    0x80115580,%ecx
801051c4:	ba cd cc cc cc       	mov    $0xcccccccd,%edx
801051c9:	89 c8                	mov    %ecx,%eax
801051cb:	f7 e2                	mul    %edx
801051cd:	c1 ea 03             	shr    $0x3,%edx
801051d0:	8d 04 92             	lea    (%edx,%edx,4),%eax
801051d3:	01 c0                	add    %eax,%eax
801051d5:	39 c1                	cmp    %eax,%ecx
801051d7:	0f 85 9b fe ff ff    	jne    80105078 <trap+0xa8>
    yield();
801051dd:	e8 df e5 ff ff       	call   801037c1 <yield>
801051e2:	e9 91 fe ff ff       	jmp    80105078 <trap+0xa8>
    exit();
801051e7:	e8 05 e5 ff ff       	call   801036f1 <exit>
801051ec:	e9 ac fe ff ff       	jmp    8010509d <trap+0xcd>

801051f1 <uartgetc>:
  outb(COM1+0, c);
}

static int
uartgetc(void)
{
801051f1:	f3 0f 1e fb          	endbr32 
  if(!uart)
801051f5:	83 3d 14 c6 10 80 00 	cmpl   $0x0,0x8010c614
801051fc:	74 14                	je     80105212 <uartgetc+0x21>
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801051fe:	ba fd 03 00 00       	mov    $0x3fd,%edx
80105203:	ec                   	in     (%dx),%al
    return -1;
  if(!(inb(COM1+5) & 0x01))
80105204:	a8 01                	test   $0x1,%al
80105206:	74 10                	je     80105218 <uartgetc+0x27>
80105208:	ba f8 03 00 00       	mov    $0x3f8,%edx
8010520d:	ec                   	in     (%dx),%al
    return -1;
  return inb(COM1+0);
8010520e:	0f b6 c0             	movzbl %al,%eax
80105211:	c3                   	ret    
    return -1;
80105212:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105217:	c3                   	ret    
    return -1;
80105218:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010521d:	c3                   	ret    

8010521e <uartputc>:
{
8010521e:	f3 0f 1e fb          	endbr32 
  if(!uart)
80105222:	83 3d 14 c6 10 80 00 	cmpl   $0x0,0x8010c614
80105229:	74 3b                	je     80105266 <uartputc+0x48>
{
8010522b:	55                   	push   %ebp
8010522c:	89 e5                	mov    %esp,%ebp
8010522e:	53                   	push   %ebx
8010522f:	83 ec 04             	sub    $0x4,%esp
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80105232:	bb 00 00 00 00       	mov    $0x0,%ebx
80105237:	83 fb 7f             	cmp    $0x7f,%ebx
8010523a:	7f 1c                	jg     80105258 <uartputc+0x3a>
8010523c:	ba fd 03 00 00       	mov    $0x3fd,%edx
80105241:	ec                   	in     (%dx),%al
80105242:	a8 20                	test   $0x20,%al
80105244:	75 12                	jne    80105258 <uartputc+0x3a>
    microdelay(10);
80105246:	83 ec 0c             	sub    $0xc,%esp
80105249:	6a 0a                	push   $0xa
8010524b:	e8 45 d2 ff ff       	call   80102495 <microdelay>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80105250:	83 c3 01             	add    $0x1,%ebx
80105253:	83 c4 10             	add    $0x10,%esp
80105256:	eb df                	jmp    80105237 <uartputc+0x19>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80105258:	8b 45 08             	mov    0x8(%ebp),%eax
8010525b:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105260:	ee                   	out    %al,(%dx)
}
80105261:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80105264:	c9                   	leave  
80105265:	c3                   	ret    
80105266:	c3                   	ret    

80105267 <uartinit>:
{
80105267:	f3 0f 1e fb          	endbr32 
8010526b:	55                   	push   %ebp
8010526c:	89 e5                	mov    %esp,%ebp
8010526e:	56                   	push   %esi
8010526f:	53                   	push   %ebx
80105270:	b9 00 00 00 00       	mov    $0x0,%ecx
80105275:	ba fa 03 00 00       	mov    $0x3fa,%edx
8010527a:	89 c8                	mov    %ecx,%eax
8010527c:	ee                   	out    %al,(%dx)
8010527d:	be fb 03 00 00       	mov    $0x3fb,%esi
80105282:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
80105287:	89 f2                	mov    %esi,%edx
80105289:	ee                   	out    %al,(%dx)
8010528a:	b8 0c 00 00 00       	mov    $0xc,%eax
8010528f:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105294:	ee                   	out    %al,(%dx)
80105295:	bb f9 03 00 00       	mov    $0x3f9,%ebx
8010529a:	89 c8                	mov    %ecx,%eax
8010529c:	89 da                	mov    %ebx,%edx
8010529e:	ee                   	out    %al,(%dx)
8010529f:	b8 03 00 00 00       	mov    $0x3,%eax
801052a4:	89 f2                	mov    %esi,%edx
801052a6:	ee                   	out    %al,(%dx)
801052a7:	ba fc 03 00 00       	mov    $0x3fc,%edx
801052ac:	89 c8                	mov    %ecx,%eax
801052ae:	ee                   	out    %al,(%dx)
801052af:	b8 01 00 00 00       	mov    $0x1,%eax
801052b4:	89 da                	mov    %ebx,%edx
801052b6:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801052b7:	ba fd 03 00 00       	mov    $0x3fd,%edx
801052bc:	ec                   	in     (%dx),%al
  if(inb(COM1+5) == 0xFF)
801052bd:	3c ff                	cmp    $0xff,%al
801052bf:	74 45                	je     80105306 <uartinit+0x9f>
  uart = 1;
801052c1:	c7 05 14 c6 10 80 01 	movl   $0x1,0x8010c614
801052c8:	00 00 00 
801052cb:	ba fa 03 00 00       	mov    $0x3fa,%edx
801052d0:	ec                   	in     (%dx),%al
801052d1:	ba f8 03 00 00       	mov    $0x3f8,%edx
801052d6:	ec                   	in     (%dx),%al
  ioapicenable(IRQ_COM1, 0);
801052d7:	83 ec 08             	sub    $0x8,%esp
801052da:	6a 00                	push   $0x0
801052dc:	6a 04                	push   $0x4
801052de:	e8 55 cd ff ff       	call   80102038 <ioapicenable>
  for(p="xv6...\n"; *p; p++)
801052e3:	83 c4 10             	add    $0x10,%esp
801052e6:	bb 44 6f 10 80       	mov    $0x80106f44,%ebx
801052eb:	eb 12                	jmp    801052ff <uartinit+0x98>
    uartputc(*p);
801052ed:	83 ec 0c             	sub    $0xc,%esp
801052f0:	0f be c0             	movsbl %al,%eax
801052f3:	50                   	push   %eax
801052f4:	e8 25 ff ff ff       	call   8010521e <uartputc>
  for(p="xv6...\n"; *p; p++)
801052f9:	83 c3 01             	add    $0x1,%ebx
801052fc:	83 c4 10             	add    $0x10,%esp
801052ff:	0f b6 03             	movzbl (%ebx),%eax
80105302:	84 c0                	test   %al,%al
80105304:	75 e7                	jne    801052ed <uartinit+0x86>
}
80105306:	8d 65 f8             	lea    -0x8(%ebp),%esp
80105309:	5b                   	pop    %ebx
8010530a:	5e                   	pop    %esi
8010530b:	5d                   	pop    %ebp
8010530c:	c3                   	ret    

8010530d <uartintr>:

void
uartintr(void)
{
8010530d:	f3 0f 1e fb          	endbr32 
80105311:	55                   	push   %ebp
80105312:	89 e5                	mov    %esp,%ebp
80105314:	83 ec 14             	sub    $0x14,%esp
  consoleintr(uartgetc);
80105317:	68 f1 51 10 80       	push   $0x801051f1
8010531c:	e8 5d b4 ff ff       	call   8010077e <consoleintr>
}
80105321:	83 c4 10             	add    $0x10,%esp
80105324:	c9                   	leave  
80105325:	c3                   	ret    

80105326 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80105326:	6a 00                	push   $0x0
  pushl $0
80105328:	6a 00                	push   $0x0
  jmp alltraps
8010532a:	e9 bd fb ff ff       	jmp    80104eec <alltraps>

8010532f <vector1>:
.globl vector1
vector1:
  pushl $0
8010532f:	6a 00                	push   $0x0
  pushl $1
80105331:	6a 01                	push   $0x1
  jmp alltraps
80105333:	e9 b4 fb ff ff       	jmp    80104eec <alltraps>

80105338 <vector2>:
.globl vector2
vector2:
  pushl $0
80105338:	6a 00                	push   $0x0
  pushl $2
8010533a:	6a 02                	push   $0x2
  jmp alltraps
8010533c:	e9 ab fb ff ff       	jmp    80104eec <alltraps>

80105341 <vector3>:
.globl vector3
vector3:
  pushl $0
80105341:	6a 00                	push   $0x0
  pushl $3
80105343:	6a 03                	push   $0x3
  jmp alltraps
80105345:	e9 a2 fb ff ff       	jmp    80104eec <alltraps>

8010534a <vector4>:
.globl vector4
vector4:
  pushl $0
8010534a:	6a 00                	push   $0x0
  pushl $4
8010534c:	6a 04                	push   $0x4
  jmp alltraps
8010534e:	e9 99 fb ff ff       	jmp    80104eec <alltraps>

80105353 <vector5>:
.globl vector5
vector5:
  pushl $0
80105353:	6a 00                	push   $0x0
  pushl $5
80105355:	6a 05                	push   $0x5
  jmp alltraps
80105357:	e9 90 fb ff ff       	jmp    80104eec <alltraps>

8010535c <vector6>:
.globl vector6
vector6:
  pushl $0
8010535c:	6a 00                	push   $0x0
  pushl $6
8010535e:	6a 06                	push   $0x6
  jmp alltraps
80105360:	e9 87 fb ff ff       	jmp    80104eec <alltraps>

80105365 <vector7>:
.globl vector7
vector7:
  pushl $0
80105365:	6a 00                	push   $0x0
  pushl $7
80105367:	6a 07                	push   $0x7
  jmp alltraps
80105369:	e9 7e fb ff ff       	jmp    80104eec <alltraps>

8010536e <vector8>:
.globl vector8
vector8:
  pushl $8
8010536e:	6a 08                	push   $0x8
  jmp alltraps
80105370:	e9 77 fb ff ff       	jmp    80104eec <alltraps>

80105375 <vector9>:
.globl vector9
vector9:
  pushl $0
80105375:	6a 00                	push   $0x0
  pushl $9
80105377:	6a 09                	push   $0x9
  jmp alltraps
80105379:	e9 6e fb ff ff       	jmp    80104eec <alltraps>

8010537e <vector10>:
.globl vector10
vector10:
  pushl $10
8010537e:	6a 0a                	push   $0xa
  jmp alltraps
80105380:	e9 67 fb ff ff       	jmp    80104eec <alltraps>

80105385 <vector11>:
.globl vector11
vector11:
  pushl $11
80105385:	6a 0b                	push   $0xb
  jmp alltraps
80105387:	e9 60 fb ff ff       	jmp    80104eec <alltraps>

8010538c <vector12>:
.globl vector12
vector12:
  pushl $12
8010538c:	6a 0c                	push   $0xc
  jmp alltraps
8010538e:	e9 59 fb ff ff       	jmp    80104eec <alltraps>

80105393 <vector13>:
.globl vector13
vector13:
  pushl $13
80105393:	6a 0d                	push   $0xd
  jmp alltraps
80105395:	e9 52 fb ff ff       	jmp    80104eec <alltraps>

8010539a <vector14>:
.globl vector14
vector14:
  pushl $14
8010539a:	6a 0e                	push   $0xe
  jmp alltraps
8010539c:	e9 4b fb ff ff       	jmp    80104eec <alltraps>

801053a1 <vector15>:
.globl vector15
vector15:
  pushl $0
801053a1:	6a 00                	push   $0x0
  pushl $15
801053a3:	6a 0f                	push   $0xf
  jmp alltraps
801053a5:	e9 42 fb ff ff       	jmp    80104eec <alltraps>

801053aa <vector16>:
.globl vector16
vector16:
  pushl $0
801053aa:	6a 00                	push   $0x0
  pushl $16
801053ac:	6a 10                	push   $0x10
  jmp alltraps
801053ae:	e9 39 fb ff ff       	jmp    80104eec <alltraps>

801053b3 <vector17>:
.globl vector17
vector17:
  pushl $17
801053b3:	6a 11                	push   $0x11
  jmp alltraps
801053b5:	e9 32 fb ff ff       	jmp    80104eec <alltraps>

801053ba <vector18>:
.globl vector18
vector18:
  pushl $0
801053ba:	6a 00                	push   $0x0
  pushl $18
801053bc:	6a 12                	push   $0x12
  jmp alltraps
801053be:	e9 29 fb ff ff       	jmp    80104eec <alltraps>

801053c3 <vector19>:
.globl vector19
vector19:
  pushl $0
801053c3:	6a 00                	push   $0x0
  pushl $19
801053c5:	6a 13                	push   $0x13
  jmp alltraps
801053c7:	e9 20 fb ff ff       	jmp    80104eec <alltraps>

801053cc <vector20>:
.globl vector20
vector20:
  pushl $0
801053cc:	6a 00                	push   $0x0
  pushl $20
801053ce:	6a 14                	push   $0x14
  jmp alltraps
801053d0:	e9 17 fb ff ff       	jmp    80104eec <alltraps>

801053d5 <vector21>:
.globl vector21
vector21:
  pushl $0
801053d5:	6a 00                	push   $0x0
  pushl $21
801053d7:	6a 15                	push   $0x15
  jmp alltraps
801053d9:	e9 0e fb ff ff       	jmp    80104eec <alltraps>

801053de <vector22>:
.globl vector22
vector22:
  pushl $0
801053de:	6a 00                	push   $0x0
  pushl $22
801053e0:	6a 16                	push   $0x16
  jmp alltraps
801053e2:	e9 05 fb ff ff       	jmp    80104eec <alltraps>

801053e7 <vector23>:
.globl vector23
vector23:
  pushl $0
801053e7:	6a 00                	push   $0x0
  pushl $23
801053e9:	6a 17                	push   $0x17
  jmp alltraps
801053eb:	e9 fc fa ff ff       	jmp    80104eec <alltraps>

801053f0 <vector24>:
.globl vector24
vector24:
  pushl $0
801053f0:	6a 00                	push   $0x0
  pushl $24
801053f2:	6a 18                	push   $0x18
  jmp alltraps
801053f4:	e9 f3 fa ff ff       	jmp    80104eec <alltraps>

801053f9 <vector25>:
.globl vector25
vector25:
  pushl $0
801053f9:	6a 00                	push   $0x0
  pushl $25
801053fb:	6a 19                	push   $0x19
  jmp alltraps
801053fd:	e9 ea fa ff ff       	jmp    80104eec <alltraps>

80105402 <vector26>:
.globl vector26
vector26:
  pushl $0
80105402:	6a 00                	push   $0x0
  pushl $26
80105404:	6a 1a                	push   $0x1a
  jmp alltraps
80105406:	e9 e1 fa ff ff       	jmp    80104eec <alltraps>

8010540b <vector27>:
.globl vector27
vector27:
  pushl $0
8010540b:	6a 00                	push   $0x0
  pushl $27
8010540d:	6a 1b                	push   $0x1b
  jmp alltraps
8010540f:	e9 d8 fa ff ff       	jmp    80104eec <alltraps>

80105414 <vector28>:
.globl vector28
vector28:
  pushl $0
80105414:	6a 00                	push   $0x0
  pushl $28
80105416:	6a 1c                	push   $0x1c
  jmp alltraps
80105418:	e9 cf fa ff ff       	jmp    80104eec <alltraps>

8010541d <vector29>:
.globl vector29
vector29:
  pushl $0
8010541d:	6a 00                	push   $0x0
  pushl $29
8010541f:	6a 1d                	push   $0x1d
  jmp alltraps
80105421:	e9 c6 fa ff ff       	jmp    80104eec <alltraps>

80105426 <vector30>:
.globl vector30
vector30:
  pushl $0
80105426:	6a 00                	push   $0x0
  pushl $30
80105428:	6a 1e                	push   $0x1e
  jmp alltraps
8010542a:	e9 bd fa ff ff       	jmp    80104eec <alltraps>

8010542f <vector31>:
.globl vector31
vector31:
  pushl $0
8010542f:	6a 00                	push   $0x0
  pushl $31
80105431:	6a 1f                	push   $0x1f
  jmp alltraps
80105433:	e9 b4 fa ff ff       	jmp    80104eec <alltraps>

80105438 <vector32>:
.globl vector32
vector32:
  pushl $0
80105438:	6a 00                	push   $0x0
  pushl $32
8010543a:	6a 20                	push   $0x20
  jmp alltraps
8010543c:	e9 ab fa ff ff       	jmp    80104eec <alltraps>

80105441 <vector33>:
.globl vector33
vector33:
  pushl $0
80105441:	6a 00                	push   $0x0
  pushl $33
80105443:	6a 21                	push   $0x21
  jmp alltraps
80105445:	e9 a2 fa ff ff       	jmp    80104eec <alltraps>

8010544a <vector34>:
.globl vector34
vector34:
  pushl $0
8010544a:	6a 00                	push   $0x0
  pushl $34
8010544c:	6a 22                	push   $0x22
  jmp alltraps
8010544e:	e9 99 fa ff ff       	jmp    80104eec <alltraps>

80105453 <vector35>:
.globl vector35
vector35:
  pushl $0
80105453:	6a 00                	push   $0x0
  pushl $35
80105455:	6a 23                	push   $0x23
  jmp alltraps
80105457:	e9 90 fa ff ff       	jmp    80104eec <alltraps>

8010545c <vector36>:
.globl vector36
vector36:
  pushl $0
8010545c:	6a 00                	push   $0x0
  pushl $36
8010545e:	6a 24                	push   $0x24
  jmp alltraps
80105460:	e9 87 fa ff ff       	jmp    80104eec <alltraps>

80105465 <vector37>:
.globl vector37
vector37:
  pushl $0
80105465:	6a 00                	push   $0x0
  pushl $37
80105467:	6a 25                	push   $0x25
  jmp alltraps
80105469:	e9 7e fa ff ff       	jmp    80104eec <alltraps>

8010546e <vector38>:
.globl vector38
vector38:
  pushl $0
8010546e:	6a 00                	push   $0x0
  pushl $38
80105470:	6a 26                	push   $0x26
  jmp alltraps
80105472:	e9 75 fa ff ff       	jmp    80104eec <alltraps>

80105477 <vector39>:
.globl vector39
vector39:
  pushl $0
80105477:	6a 00                	push   $0x0
  pushl $39
80105479:	6a 27                	push   $0x27
  jmp alltraps
8010547b:	e9 6c fa ff ff       	jmp    80104eec <alltraps>

80105480 <vector40>:
.globl vector40
vector40:
  pushl $0
80105480:	6a 00                	push   $0x0
  pushl $40
80105482:	6a 28                	push   $0x28
  jmp alltraps
80105484:	e9 63 fa ff ff       	jmp    80104eec <alltraps>

80105489 <vector41>:
.globl vector41
vector41:
  pushl $0
80105489:	6a 00                	push   $0x0
  pushl $41
8010548b:	6a 29                	push   $0x29
  jmp alltraps
8010548d:	e9 5a fa ff ff       	jmp    80104eec <alltraps>

80105492 <vector42>:
.globl vector42
vector42:
  pushl $0
80105492:	6a 00                	push   $0x0
  pushl $42
80105494:	6a 2a                	push   $0x2a
  jmp alltraps
80105496:	e9 51 fa ff ff       	jmp    80104eec <alltraps>

8010549b <vector43>:
.globl vector43
vector43:
  pushl $0
8010549b:	6a 00                	push   $0x0
  pushl $43
8010549d:	6a 2b                	push   $0x2b
  jmp alltraps
8010549f:	e9 48 fa ff ff       	jmp    80104eec <alltraps>

801054a4 <vector44>:
.globl vector44
vector44:
  pushl $0
801054a4:	6a 00                	push   $0x0
  pushl $44
801054a6:	6a 2c                	push   $0x2c
  jmp alltraps
801054a8:	e9 3f fa ff ff       	jmp    80104eec <alltraps>

801054ad <vector45>:
.globl vector45
vector45:
  pushl $0
801054ad:	6a 00                	push   $0x0
  pushl $45
801054af:	6a 2d                	push   $0x2d
  jmp alltraps
801054b1:	e9 36 fa ff ff       	jmp    80104eec <alltraps>

801054b6 <vector46>:
.globl vector46
vector46:
  pushl $0
801054b6:	6a 00                	push   $0x0
  pushl $46
801054b8:	6a 2e                	push   $0x2e
  jmp alltraps
801054ba:	e9 2d fa ff ff       	jmp    80104eec <alltraps>

801054bf <vector47>:
.globl vector47
vector47:
  pushl $0
801054bf:	6a 00                	push   $0x0
  pushl $47
801054c1:	6a 2f                	push   $0x2f
  jmp alltraps
801054c3:	e9 24 fa ff ff       	jmp    80104eec <alltraps>

801054c8 <vector48>:
.globl vector48
vector48:
  pushl $0
801054c8:	6a 00                	push   $0x0
  pushl $48
801054ca:	6a 30                	push   $0x30
  jmp alltraps
801054cc:	e9 1b fa ff ff       	jmp    80104eec <alltraps>

801054d1 <vector49>:
.globl vector49
vector49:
  pushl $0
801054d1:	6a 00                	push   $0x0
  pushl $49
801054d3:	6a 31                	push   $0x31
  jmp alltraps
801054d5:	e9 12 fa ff ff       	jmp    80104eec <alltraps>

801054da <vector50>:
.globl vector50
vector50:
  pushl $0
801054da:	6a 00                	push   $0x0
  pushl $50
801054dc:	6a 32                	push   $0x32
  jmp alltraps
801054de:	e9 09 fa ff ff       	jmp    80104eec <alltraps>

801054e3 <vector51>:
.globl vector51
vector51:
  pushl $0
801054e3:	6a 00                	push   $0x0
  pushl $51
801054e5:	6a 33                	push   $0x33
  jmp alltraps
801054e7:	e9 00 fa ff ff       	jmp    80104eec <alltraps>

801054ec <vector52>:
.globl vector52
vector52:
  pushl $0
801054ec:	6a 00                	push   $0x0
  pushl $52
801054ee:	6a 34                	push   $0x34
  jmp alltraps
801054f0:	e9 f7 f9 ff ff       	jmp    80104eec <alltraps>

801054f5 <vector53>:
.globl vector53
vector53:
  pushl $0
801054f5:	6a 00                	push   $0x0
  pushl $53
801054f7:	6a 35                	push   $0x35
  jmp alltraps
801054f9:	e9 ee f9 ff ff       	jmp    80104eec <alltraps>

801054fe <vector54>:
.globl vector54
vector54:
  pushl $0
801054fe:	6a 00                	push   $0x0
  pushl $54
80105500:	6a 36                	push   $0x36
  jmp alltraps
80105502:	e9 e5 f9 ff ff       	jmp    80104eec <alltraps>

80105507 <vector55>:
.globl vector55
vector55:
  pushl $0
80105507:	6a 00                	push   $0x0
  pushl $55
80105509:	6a 37                	push   $0x37
  jmp alltraps
8010550b:	e9 dc f9 ff ff       	jmp    80104eec <alltraps>

80105510 <vector56>:
.globl vector56
vector56:
  pushl $0
80105510:	6a 00                	push   $0x0
  pushl $56
80105512:	6a 38                	push   $0x38
  jmp alltraps
80105514:	e9 d3 f9 ff ff       	jmp    80104eec <alltraps>

80105519 <vector57>:
.globl vector57
vector57:
  pushl $0
80105519:	6a 00                	push   $0x0
  pushl $57
8010551b:	6a 39                	push   $0x39
  jmp alltraps
8010551d:	e9 ca f9 ff ff       	jmp    80104eec <alltraps>

80105522 <vector58>:
.globl vector58
vector58:
  pushl $0
80105522:	6a 00                	push   $0x0
  pushl $58
80105524:	6a 3a                	push   $0x3a
  jmp alltraps
80105526:	e9 c1 f9 ff ff       	jmp    80104eec <alltraps>

8010552b <vector59>:
.globl vector59
vector59:
  pushl $0
8010552b:	6a 00                	push   $0x0
  pushl $59
8010552d:	6a 3b                	push   $0x3b
  jmp alltraps
8010552f:	e9 b8 f9 ff ff       	jmp    80104eec <alltraps>

80105534 <vector60>:
.globl vector60
vector60:
  pushl $0
80105534:	6a 00                	push   $0x0
  pushl $60
80105536:	6a 3c                	push   $0x3c
  jmp alltraps
80105538:	e9 af f9 ff ff       	jmp    80104eec <alltraps>

8010553d <vector61>:
.globl vector61
vector61:
  pushl $0
8010553d:	6a 00                	push   $0x0
  pushl $61
8010553f:	6a 3d                	push   $0x3d
  jmp alltraps
80105541:	e9 a6 f9 ff ff       	jmp    80104eec <alltraps>

80105546 <vector62>:
.globl vector62
vector62:
  pushl $0
80105546:	6a 00                	push   $0x0
  pushl $62
80105548:	6a 3e                	push   $0x3e
  jmp alltraps
8010554a:	e9 9d f9 ff ff       	jmp    80104eec <alltraps>

8010554f <vector63>:
.globl vector63
vector63:
  pushl $0
8010554f:	6a 00                	push   $0x0
  pushl $63
80105551:	6a 3f                	push   $0x3f
  jmp alltraps
80105553:	e9 94 f9 ff ff       	jmp    80104eec <alltraps>

80105558 <vector64>:
.globl vector64
vector64:
  pushl $0
80105558:	6a 00                	push   $0x0
  pushl $64
8010555a:	6a 40                	push   $0x40
  jmp alltraps
8010555c:	e9 8b f9 ff ff       	jmp    80104eec <alltraps>

80105561 <vector65>:
.globl vector65
vector65:
  pushl $0
80105561:	6a 00                	push   $0x0
  pushl $65
80105563:	6a 41                	push   $0x41
  jmp alltraps
80105565:	e9 82 f9 ff ff       	jmp    80104eec <alltraps>

8010556a <vector66>:
.globl vector66
vector66:
  pushl $0
8010556a:	6a 00                	push   $0x0
  pushl $66
8010556c:	6a 42                	push   $0x42
  jmp alltraps
8010556e:	e9 79 f9 ff ff       	jmp    80104eec <alltraps>

80105573 <vector67>:
.globl vector67
vector67:
  pushl $0
80105573:	6a 00                	push   $0x0
  pushl $67
80105575:	6a 43                	push   $0x43
  jmp alltraps
80105577:	e9 70 f9 ff ff       	jmp    80104eec <alltraps>

8010557c <vector68>:
.globl vector68
vector68:
  pushl $0
8010557c:	6a 00                	push   $0x0
  pushl $68
8010557e:	6a 44                	push   $0x44
  jmp alltraps
80105580:	e9 67 f9 ff ff       	jmp    80104eec <alltraps>

80105585 <vector69>:
.globl vector69
vector69:
  pushl $0
80105585:	6a 00                	push   $0x0
  pushl $69
80105587:	6a 45                	push   $0x45
  jmp alltraps
80105589:	e9 5e f9 ff ff       	jmp    80104eec <alltraps>

8010558e <vector70>:
.globl vector70
vector70:
  pushl $0
8010558e:	6a 00                	push   $0x0
  pushl $70
80105590:	6a 46                	push   $0x46
  jmp alltraps
80105592:	e9 55 f9 ff ff       	jmp    80104eec <alltraps>

80105597 <vector71>:
.globl vector71
vector71:
  pushl $0
80105597:	6a 00                	push   $0x0
  pushl $71
80105599:	6a 47                	push   $0x47
  jmp alltraps
8010559b:	e9 4c f9 ff ff       	jmp    80104eec <alltraps>

801055a0 <vector72>:
.globl vector72
vector72:
  pushl $0
801055a0:	6a 00                	push   $0x0
  pushl $72
801055a2:	6a 48                	push   $0x48
  jmp alltraps
801055a4:	e9 43 f9 ff ff       	jmp    80104eec <alltraps>

801055a9 <vector73>:
.globl vector73
vector73:
  pushl $0
801055a9:	6a 00                	push   $0x0
  pushl $73
801055ab:	6a 49                	push   $0x49
  jmp alltraps
801055ad:	e9 3a f9 ff ff       	jmp    80104eec <alltraps>

801055b2 <vector74>:
.globl vector74
vector74:
  pushl $0
801055b2:	6a 00                	push   $0x0
  pushl $74
801055b4:	6a 4a                	push   $0x4a
  jmp alltraps
801055b6:	e9 31 f9 ff ff       	jmp    80104eec <alltraps>

801055bb <vector75>:
.globl vector75
vector75:
  pushl $0
801055bb:	6a 00                	push   $0x0
  pushl $75
801055bd:	6a 4b                	push   $0x4b
  jmp alltraps
801055bf:	e9 28 f9 ff ff       	jmp    80104eec <alltraps>

801055c4 <vector76>:
.globl vector76
vector76:
  pushl $0
801055c4:	6a 00                	push   $0x0
  pushl $76
801055c6:	6a 4c                	push   $0x4c
  jmp alltraps
801055c8:	e9 1f f9 ff ff       	jmp    80104eec <alltraps>

801055cd <vector77>:
.globl vector77
vector77:
  pushl $0
801055cd:	6a 00                	push   $0x0
  pushl $77
801055cf:	6a 4d                	push   $0x4d
  jmp alltraps
801055d1:	e9 16 f9 ff ff       	jmp    80104eec <alltraps>

801055d6 <vector78>:
.globl vector78
vector78:
  pushl $0
801055d6:	6a 00                	push   $0x0
  pushl $78
801055d8:	6a 4e                	push   $0x4e
  jmp alltraps
801055da:	e9 0d f9 ff ff       	jmp    80104eec <alltraps>

801055df <vector79>:
.globl vector79
vector79:
  pushl $0
801055df:	6a 00                	push   $0x0
  pushl $79
801055e1:	6a 4f                	push   $0x4f
  jmp alltraps
801055e3:	e9 04 f9 ff ff       	jmp    80104eec <alltraps>

801055e8 <vector80>:
.globl vector80
vector80:
  pushl $0
801055e8:	6a 00                	push   $0x0
  pushl $80
801055ea:	6a 50                	push   $0x50
  jmp alltraps
801055ec:	e9 fb f8 ff ff       	jmp    80104eec <alltraps>

801055f1 <vector81>:
.globl vector81
vector81:
  pushl $0
801055f1:	6a 00                	push   $0x0
  pushl $81
801055f3:	6a 51                	push   $0x51
  jmp alltraps
801055f5:	e9 f2 f8 ff ff       	jmp    80104eec <alltraps>

801055fa <vector82>:
.globl vector82
vector82:
  pushl $0
801055fa:	6a 00                	push   $0x0
  pushl $82
801055fc:	6a 52                	push   $0x52
  jmp alltraps
801055fe:	e9 e9 f8 ff ff       	jmp    80104eec <alltraps>

80105603 <vector83>:
.globl vector83
vector83:
  pushl $0
80105603:	6a 00                	push   $0x0
  pushl $83
80105605:	6a 53                	push   $0x53
  jmp alltraps
80105607:	e9 e0 f8 ff ff       	jmp    80104eec <alltraps>

8010560c <vector84>:
.globl vector84
vector84:
  pushl $0
8010560c:	6a 00                	push   $0x0
  pushl $84
8010560e:	6a 54                	push   $0x54
  jmp alltraps
80105610:	e9 d7 f8 ff ff       	jmp    80104eec <alltraps>

80105615 <vector85>:
.globl vector85
vector85:
  pushl $0
80105615:	6a 00                	push   $0x0
  pushl $85
80105617:	6a 55                	push   $0x55
  jmp alltraps
80105619:	e9 ce f8 ff ff       	jmp    80104eec <alltraps>

8010561e <vector86>:
.globl vector86
vector86:
  pushl $0
8010561e:	6a 00                	push   $0x0
  pushl $86
80105620:	6a 56                	push   $0x56
  jmp alltraps
80105622:	e9 c5 f8 ff ff       	jmp    80104eec <alltraps>

80105627 <vector87>:
.globl vector87
vector87:
  pushl $0
80105627:	6a 00                	push   $0x0
  pushl $87
80105629:	6a 57                	push   $0x57
  jmp alltraps
8010562b:	e9 bc f8 ff ff       	jmp    80104eec <alltraps>

80105630 <vector88>:
.globl vector88
vector88:
  pushl $0
80105630:	6a 00                	push   $0x0
  pushl $88
80105632:	6a 58                	push   $0x58
  jmp alltraps
80105634:	e9 b3 f8 ff ff       	jmp    80104eec <alltraps>

80105639 <vector89>:
.globl vector89
vector89:
  pushl $0
80105639:	6a 00                	push   $0x0
  pushl $89
8010563b:	6a 59                	push   $0x59
  jmp alltraps
8010563d:	e9 aa f8 ff ff       	jmp    80104eec <alltraps>

80105642 <vector90>:
.globl vector90
vector90:
  pushl $0
80105642:	6a 00                	push   $0x0
  pushl $90
80105644:	6a 5a                	push   $0x5a
  jmp alltraps
80105646:	e9 a1 f8 ff ff       	jmp    80104eec <alltraps>

8010564b <vector91>:
.globl vector91
vector91:
  pushl $0
8010564b:	6a 00                	push   $0x0
  pushl $91
8010564d:	6a 5b                	push   $0x5b
  jmp alltraps
8010564f:	e9 98 f8 ff ff       	jmp    80104eec <alltraps>

80105654 <vector92>:
.globl vector92
vector92:
  pushl $0
80105654:	6a 00                	push   $0x0
  pushl $92
80105656:	6a 5c                	push   $0x5c
  jmp alltraps
80105658:	e9 8f f8 ff ff       	jmp    80104eec <alltraps>

8010565d <vector93>:
.globl vector93
vector93:
  pushl $0
8010565d:	6a 00                	push   $0x0
  pushl $93
8010565f:	6a 5d                	push   $0x5d
  jmp alltraps
80105661:	e9 86 f8 ff ff       	jmp    80104eec <alltraps>

80105666 <vector94>:
.globl vector94
vector94:
  pushl $0
80105666:	6a 00                	push   $0x0
  pushl $94
80105668:	6a 5e                	push   $0x5e
  jmp alltraps
8010566a:	e9 7d f8 ff ff       	jmp    80104eec <alltraps>

8010566f <vector95>:
.globl vector95
vector95:
  pushl $0
8010566f:	6a 00                	push   $0x0
  pushl $95
80105671:	6a 5f                	push   $0x5f
  jmp alltraps
80105673:	e9 74 f8 ff ff       	jmp    80104eec <alltraps>

80105678 <vector96>:
.globl vector96
vector96:
  pushl $0
80105678:	6a 00                	push   $0x0
  pushl $96
8010567a:	6a 60                	push   $0x60
  jmp alltraps
8010567c:	e9 6b f8 ff ff       	jmp    80104eec <alltraps>

80105681 <vector97>:
.globl vector97
vector97:
  pushl $0
80105681:	6a 00                	push   $0x0
  pushl $97
80105683:	6a 61                	push   $0x61
  jmp alltraps
80105685:	e9 62 f8 ff ff       	jmp    80104eec <alltraps>

8010568a <vector98>:
.globl vector98
vector98:
  pushl $0
8010568a:	6a 00                	push   $0x0
  pushl $98
8010568c:	6a 62                	push   $0x62
  jmp alltraps
8010568e:	e9 59 f8 ff ff       	jmp    80104eec <alltraps>

80105693 <vector99>:
.globl vector99
vector99:
  pushl $0
80105693:	6a 00                	push   $0x0
  pushl $99
80105695:	6a 63                	push   $0x63
  jmp alltraps
80105697:	e9 50 f8 ff ff       	jmp    80104eec <alltraps>

8010569c <vector100>:
.globl vector100
vector100:
  pushl $0
8010569c:	6a 00                	push   $0x0
  pushl $100
8010569e:	6a 64                	push   $0x64
  jmp alltraps
801056a0:	e9 47 f8 ff ff       	jmp    80104eec <alltraps>

801056a5 <vector101>:
.globl vector101
vector101:
  pushl $0
801056a5:	6a 00                	push   $0x0
  pushl $101
801056a7:	6a 65                	push   $0x65
  jmp alltraps
801056a9:	e9 3e f8 ff ff       	jmp    80104eec <alltraps>

801056ae <vector102>:
.globl vector102
vector102:
  pushl $0
801056ae:	6a 00                	push   $0x0
  pushl $102
801056b0:	6a 66                	push   $0x66
  jmp alltraps
801056b2:	e9 35 f8 ff ff       	jmp    80104eec <alltraps>

801056b7 <vector103>:
.globl vector103
vector103:
  pushl $0
801056b7:	6a 00                	push   $0x0
  pushl $103
801056b9:	6a 67                	push   $0x67
  jmp alltraps
801056bb:	e9 2c f8 ff ff       	jmp    80104eec <alltraps>

801056c0 <vector104>:
.globl vector104
vector104:
  pushl $0
801056c0:	6a 00                	push   $0x0
  pushl $104
801056c2:	6a 68                	push   $0x68
  jmp alltraps
801056c4:	e9 23 f8 ff ff       	jmp    80104eec <alltraps>

801056c9 <vector105>:
.globl vector105
vector105:
  pushl $0
801056c9:	6a 00                	push   $0x0
  pushl $105
801056cb:	6a 69                	push   $0x69
  jmp alltraps
801056cd:	e9 1a f8 ff ff       	jmp    80104eec <alltraps>

801056d2 <vector106>:
.globl vector106
vector106:
  pushl $0
801056d2:	6a 00                	push   $0x0
  pushl $106
801056d4:	6a 6a                	push   $0x6a
  jmp alltraps
801056d6:	e9 11 f8 ff ff       	jmp    80104eec <alltraps>

801056db <vector107>:
.globl vector107
vector107:
  pushl $0
801056db:	6a 00                	push   $0x0
  pushl $107
801056dd:	6a 6b                	push   $0x6b
  jmp alltraps
801056df:	e9 08 f8 ff ff       	jmp    80104eec <alltraps>

801056e4 <vector108>:
.globl vector108
vector108:
  pushl $0
801056e4:	6a 00                	push   $0x0
  pushl $108
801056e6:	6a 6c                	push   $0x6c
  jmp alltraps
801056e8:	e9 ff f7 ff ff       	jmp    80104eec <alltraps>

801056ed <vector109>:
.globl vector109
vector109:
  pushl $0
801056ed:	6a 00                	push   $0x0
  pushl $109
801056ef:	6a 6d                	push   $0x6d
  jmp alltraps
801056f1:	e9 f6 f7 ff ff       	jmp    80104eec <alltraps>

801056f6 <vector110>:
.globl vector110
vector110:
  pushl $0
801056f6:	6a 00                	push   $0x0
  pushl $110
801056f8:	6a 6e                	push   $0x6e
  jmp alltraps
801056fa:	e9 ed f7 ff ff       	jmp    80104eec <alltraps>

801056ff <vector111>:
.globl vector111
vector111:
  pushl $0
801056ff:	6a 00                	push   $0x0
  pushl $111
80105701:	6a 6f                	push   $0x6f
  jmp alltraps
80105703:	e9 e4 f7 ff ff       	jmp    80104eec <alltraps>

80105708 <vector112>:
.globl vector112
vector112:
  pushl $0
80105708:	6a 00                	push   $0x0
  pushl $112
8010570a:	6a 70                	push   $0x70
  jmp alltraps
8010570c:	e9 db f7 ff ff       	jmp    80104eec <alltraps>

80105711 <vector113>:
.globl vector113
vector113:
  pushl $0
80105711:	6a 00                	push   $0x0
  pushl $113
80105713:	6a 71                	push   $0x71
  jmp alltraps
80105715:	e9 d2 f7 ff ff       	jmp    80104eec <alltraps>

8010571a <vector114>:
.globl vector114
vector114:
  pushl $0
8010571a:	6a 00                	push   $0x0
  pushl $114
8010571c:	6a 72                	push   $0x72
  jmp alltraps
8010571e:	e9 c9 f7 ff ff       	jmp    80104eec <alltraps>

80105723 <vector115>:
.globl vector115
vector115:
  pushl $0
80105723:	6a 00                	push   $0x0
  pushl $115
80105725:	6a 73                	push   $0x73
  jmp alltraps
80105727:	e9 c0 f7 ff ff       	jmp    80104eec <alltraps>

8010572c <vector116>:
.globl vector116
vector116:
  pushl $0
8010572c:	6a 00                	push   $0x0
  pushl $116
8010572e:	6a 74                	push   $0x74
  jmp alltraps
80105730:	e9 b7 f7 ff ff       	jmp    80104eec <alltraps>

80105735 <vector117>:
.globl vector117
vector117:
  pushl $0
80105735:	6a 00                	push   $0x0
  pushl $117
80105737:	6a 75                	push   $0x75
  jmp alltraps
80105739:	e9 ae f7 ff ff       	jmp    80104eec <alltraps>

8010573e <vector118>:
.globl vector118
vector118:
  pushl $0
8010573e:	6a 00                	push   $0x0
  pushl $118
80105740:	6a 76                	push   $0x76
  jmp alltraps
80105742:	e9 a5 f7 ff ff       	jmp    80104eec <alltraps>

80105747 <vector119>:
.globl vector119
vector119:
  pushl $0
80105747:	6a 00                	push   $0x0
  pushl $119
80105749:	6a 77                	push   $0x77
  jmp alltraps
8010574b:	e9 9c f7 ff ff       	jmp    80104eec <alltraps>

80105750 <vector120>:
.globl vector120
vector120:
  pushl $0
80105750:	6a 00                	push   $0x0
  pushl $120
80105752:	6a 78                	push   $0x78
  jmp alltraps
80105754:	e9 93 f7 ff ff       	jmp    80104eec <alltraps>

80105759 <vector121>:
.globl vector121
vector121:
  pushl $0
80105759:	6a 00                	push   $0x0
  pushl $121
8010575b:	6a 79                	push   $0x79
  jmp alltraps
8010575d:	e9 8a f7 ff ff       	jmp    80104eec <alltraps>

80105762 <vector122>:
.globl vector122
vector122:
  pushl $0
80105762:	6a 00                	push   $0x0
  pushl $122
80105764:	6a 7a                	push   $0x7a
  jmp alltraps
80105766:	e9 81 f7 ff ff       	jmp    80104eec <alltraps>

8010576b <vector123>:
.globl vector123
vector123:
  pushl $0
8010576b:	6a 00                	push   $0x0
  pushl $123
8010576d:	6a 7b                	push   $0x7b
  jmp alltraps
8010576f:	e9 78 f7 ff ff       	jmp    80104eec <alltraps>

80105774 <vector124>:
.globl vector124
vector124:
  pushl $0
80105774:	6a 00                	push   $0x0
  pushl $124
80105776:	6a 7c                	push   $0x7c
  jmp alltraps
80105778:	e9 6f f7 ff ff       	jmp    80104eec <alltraps>

8010577d <vector125>:
.globl vector125
vector125:
  pushl $0
8010577d:	6a 00                	push   $0x0
  pushl $125
8010577f:	6a 7d                	push   $0x7d
  jmp alltraps
80105781:	e9 66 f7 ff ff       	jmp    80104eec <alltraps>

80105786 <vector126>:
.globl vector126
vector126:
  pushl $0
80105786:	6a 00                	push   $0x0
  pushl $126
80105788:	6a 7e                	push   $0x7e
  jmp alltraps
8010578a:	e9 5d f7 ff ff       	jmp    80104eec <alltraps>

8010578f <vector127>:
.globl vector127
vector127:
  pushl $0
8010578f:	6a 00                	push   $0x0
  pushl $127
80105791:	6a 7f                	push   $0x7f
  jmp alltraps
80105793:	e9 54 f7 ff ff       	jmp    80104eec <alltraps>

80105798 <vector128>:
.globl vector128
vector128:
  pushl $0
80105798:	6a 00                	push   $0x0
  pushl $128
8010579a:	68 80 00 00 00       	push   $0x80
  jmp alltraps
8010579f:	e9 48 f7 ff ff       	jmp    80104eec <alltraps>

801057a4 <vector129>:
.globl vector129
vector129:
  pushl $0
801057a4:	6a 00                	push   $0x0
  pushl $129
801057a6:	68 81 00 00 00       	push   $0x81
  jmp alltraps
801057ab:	e9 3c f7 ff ff       	jmp    80104eec <alltraps>

801057b0 <vector130>:
.globl vector130
vector130:
  pushl $0
801057b0:	6a 00                	push   $0x0
  pushl $130
801057b2:	68 82 00 00 00       	push   $0x82
  jmp alltraps
801057b7:	e9 30 f7 ff ff       	jmp    80104eec <alltraps>

801057bc <vector131>:
.globl vector131
vector131:
  pushl $0
801057bc:	6a 00                	push   $0x0
  pushl $131
801057be:	68 83 00 00 00       	push   $0x83
  jmp alltraps
801057c3:	e9 24 f7 ff ff       	jmp    80104eec <alltraps>

801057c8 <vector132>:
.globl vector132
vector132:
  pushl $0
801057c8:	6a 00                	push   $0x0
  pushl $132
801057ca:	68 84 00 00 00       	push   $0x84
  jmp alltraps
801057cf:	e9 18 f7 ff ff       	jmp    80104eec <alltraps>

801057d4 <vector133>:
.globl vector133
vector133:
  pushl $0
801057d4:	6a 00                	push   $0x0
  pushl $133
801057d6:	68 85 00 00 00       	push   $0x85
  jmp alltraps
801057db:	e9 0c f7 ff ff       	jmp    80104eec <alltraps>

801057e0 <vector134>:
.globl vector134
vector134:
  pushl $0
801057e0:	6a 00                	push   $0x0
  pushl $134
801057e2:	68 86 00 00 00       	push   $0x86
  jmp alltraps
801057e7:	e9 00 f7 ff ff       	jmp    80104eec <alltraps>

801057ec <vector135>:
.globl vector135
vector135:
  pushl $0
801057ec:	6a 00                	push   $0x0
  pushl $135
801057ee:	68 87 00 00 00       	push   $0x87
  jmp alltraps
801057f3:	e9 f4 f6 ff ff       	jmp    80104eec <alltraps>

801057f8 <vector136>:
.globl vector136
vector136:
  pushl $0
801057f8:	6a 00                	push   $0x0
  pushl $136
801057fa:	68 88 00 00 00       	push   $0x88
  jmp alltraps
801057ff:	e9 e8 f6 ff ff       	jmp    80104eec <alltraps>

80105804 <vector137>:
.globl vector137
vector137:
  pushl $0
80105804:	6a 00                	push   $0x0
  pushl $137
80105806:	68 89 00 00 00       	push   $0x89
  jmp alltraps
8010580b:	e9 dc f6 ff ff       	jmp    80104eec <alltraps>

80105810 <vector138>:
.globl vector138
vector138:
  pushl $0
80105810:	6a 00                	push   $0x0
  pushl $138
80105812:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80105817:	e9 d0 f6 ff ff       	jmp    80104eec <alltraps>

8010581c <vector139>:
.globl vector139
vector139:
  pushl $0
8010581c:	6a 00                	push   $0x0
  pushl $139
8010581e:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80105823:	e9 c4 f6 ff ff       	jmp    80104eec <alltraps>

80105828 <vector140>:
.globl vector140
vector140:
  pushl $0
80105828:	6a 00                	push   $0x0
  pushl $140
8010582a:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
8010582f:	e9 b8 f6 ff ff       	jmp    80104eec <alltraps>

80105834 <vector141>:
.globl vector141
vector141:
  pushl $0
80105834:	6a 00                	push   $0x0
  pushl $141
80105836:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
8010583b:	e9 ac f6 ff ff       	jmp    80104eec <alltraps>

80105840 <vector142>:
.globl vector142
vector142:
  pushl $0
80105840:	6a 00                	push   $0x0
  pushl $142
80105842:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80105847:	e9 a0 f6 ff ff       	jmp    80104eec <alltraps>

8010584c <vector143>:
.globl vector143
vector143:
  pushl $0
8010584c:	6a 00                	push   $0x0
  pushl $143
8010584e:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80105853:	e9 94 f6 ff ff       	jmp    80104eec <alltraps>

80105858 <vector144>:
.globl vector144
vector144:
  pushl $0
80105858:	6a 00                	push   $0x0
  pushl $144
8010585a:	68 90 00 00 00       	push   $0x90
  jmp alltraps
8010585f:	e9 88 f6 ff ff       	jmp    80104eec <alltraps>

80105864 <vector145>:
.globl vector145
vector145:
  pushl $0
80105864:	6a 00                	push   $0x0
  pushl $145
80105866:	68 91 00 00 00       	push   $0x91
  jmp alltraps
8010586b:	e9 7c f6 ff ff       	jmp    80104eec <alltraps>

80105870 <vector146>:
.globl vector146
vector146:
  pushl $0
80105870:	6a 00                	push   $0x0
  pushl $146
80105872:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80105877:	e9 70 f6 ff ff       	jmp    80104eec <alltraps>

8010587c <vector147>:
.globl vector147
vector147:
  pushl $0
8010587c:	6a 00                	push   $0x0
  pushl $147
8010587e:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80105883:	e9 64 f6 ff ff       	jmp    80104eec <alltraps>

80105888 <vector148>:
.globl vector148
vector148:
  pushl $0
80105888:	6a 00                	push   $0x0
  pushl $148
8010588a:	68 94 00 00 00       	push   $0x94
  jmp alltraps
8010588f:	e9 58 f6 ff ff       	jmp    80104eec <alltraps>

80105894 <vector149>:
.globl vector149
vector149:
  pushl $0
80105894:	6a 00                	push   $0x0
  pushl $149
80105896:	68 95 00 00 00       	push   $0x95
  jmp alltraps
8010589b:	e9 4c f6 ff ff       	jmp    80104eec <alltraps>

801058a0 <vector150>:
.globl vector150
vector150:
  pushl $0
801058a0:	6a 00                	push   $0x0
  pushl $150
801058a2:	68 96 00 00 00       	push   $0x96
  jmp alltraps
801058a7:	e9 40 f6 ff ff       	jmp    80104eec <alltraps>

801058ac <vector151>:
.globl vector151
vector151:
  pushl $0
801058ac:	6a 00                	push   $0x0
  pushl $151
801058ae:	68 97 00 00 00       	push   $0x97
  jmp alltraps
801058b3:	e9 34 f6 ff ff       	jmp    80104eec <alltraps>

801058b8 <vector152>:
.globl vector152
vector152:
  pushl $0
801058b8:	6a 00                	push   $0x0
  pushl $152
801058ba:	68 98 00 00 00       	push   $0x98
  jmp alltraps
801058bf:	e9 28 f6 ff ff       	jmp    80104eec <alltraps>

801058c4 <vector153>:
.globl vector153
vector153:
  pushl $0
801058c4:	6a 00                	push   $0x0
  pushl $153
801058c6:	68 99 00 00 00       	push   $0x99
  jmp alltraps
801058cb:	e9 1c f6 ff ff       	jmp    80104eec <alltraps>

801058d0 <vector154>:
.globl vector154
vector154:
  pushl $0
801058d0:	6a 00                	push   $0x0
  pushl $154
801058d2:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
801058d7:	e9 10 f6 ff ff       	jmp    80104eec <alltraps>

801058dc <vector155>:
.globl vector155
vector155:
  pushl $0
801058dc:	6a 00                	push   $0x0
  pushl $155
801058de:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
801058e3:	e9 04 f6 ff ff       	jmp    80104eec <alltraps>

801058e8 <vector156>:
.globl vector156
vector156:
  pushl $0
801058e8:	6a 00                	push   $0x0
  pushl $156
801058ea:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
801058ef:	e9 f8 f5 ff ff       	jmp    80104eec <alltraps>

801058f4 <vector157>:
.globl vector157
vector157:
  pushl $0
801058f4:	6a 00                	push   $0x0
  pushl $157
801058f6:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
801058fb:	e9 ec f5 ff ff       	jmp    80104eec <alltraps>

80105900 <vector158>:
.globl vector158
vector158:
  pushl $0
80105900:	6a 00                	push   $0x0
  pushl $158
80105902:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80105907:	e9 e0 f5 ff ff       	jmp    80104eec <alltraps>

8010590c <vector159>:
.globl vector159
vector159:
  pushl $0
8010590c:	6a 00                	push   $0x0
  pushl $159
8010590e:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80105913:	e9 d4 f5 ff ff       	jmp    80104eec <alltraps>

80105918 <vector160>:
.globl vector160
vector160:
  pushl $0
80105918:	6a 00                	push   $0x0
  pushl $160
8010591a:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
8010591f:	e9 c8 f5 ff ff       	jmp    80104eec <alltraps>

80105924 <vector161>:
.globl vector161
vector161:
  pushl $0
80105924:	6a 00                	push   $0x0
  pushl $161
80105926:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
8010592b:	e9 bc f5 ff ff       	jmp    80104eec <alltraps>

80105930 <vector162>:
.globl vector162
vector162:
  pushl $0
80105930:	6a 00                	push   $0x0
  pushl $162
80105932:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80105937:	e9 b0 f5 ff ff       	jmp    80104eec <alltraps>

8010593c <vector163>:
.globl vector163
vector163:
  pushl $0
8010593c:	6a 00                	push   $0x0
  pushl $163
8010593e:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80105943:	e9 a4 f5 ff ff       	jmp    80104eec <alltraps>

80105948 <vector164>:
.globl vector164
vector164:
  pushl $0
80105948:	6a 00                	push   $0x0
  pushl $164
8010594a:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
8010594f:	e9 98 f5 ff ff       	jmp    80104eec <alltraps>

80105954 <vector165>:
.globl vector165
vector165:
  pushl $0
80105954:	6a 00                	push   $0x0
  pushl $165
80105956:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
8010595b:	e9 8c f5 ff ff       	jmp    80104eec <alltraps>

80105960 <vector166>:
.globl vector166
vector166:
  pushl $0
80105960:	6a 00                	push   $0x0
  pushl $166
80105962:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80105967:	e9 80 f5 ff ff       	jmp    80104eec <alltraps>

8010596c <vector167>:
.globl vector167
vector167:
  pushl $0
8010596c:	6a 00                	push   $0x0
  pushl $167
8010596e:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80105973:	e9 74 f5 ff ff       	jmp    80104eec <alltraps>

80105978 <vector168>:
.globl vector168
vector168:
  pushl $0
80105978:	6a 00                	push   $0x0
  pushl $168
8010597a:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
8010597f:	e9 68 f5 ff ff       	jmp    80104eec <alltraps>

80105984 <vector169>:
.globl vector169
vector169:
  pushl $0
80105984:	6a 00                	push   $0x0
  pushl $169
80105986:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
8010598b:	e9 5c f5 ff ff       	jmp    80104eec <alltraps>

80105990 <vector170>:
.globl vector170
vector170:
  pushl $0
80105990:	6a 00                	push   $0x0
  pushl $170
80105992:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80105997:	e9 50 f5 ff ff       	jmp    80104eec <alltraps>

8010599c <vector171>:
.globl vector171
vector171:
  pushl $0
8010599c:	6a 00                	push   $0x0
  pushl $171
8010599e:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
801059a3:	e9 44 f5 ff ff       	jmp    80104eec <alltraps>

801059a8 <vector172>:
.globl vector172
vector172:
  pushl $0
801059a8:	6a 00                	push   $0x0
  pushl $172
801059aa:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
801059af:	e9 38 f5 ff ff       	jmp    80104eec <alltraps>

801059b4 <vector173>:
.globl vector173
vector173:
  pushl $0
801059b4:	6a 00                	push   $0x0
  pushl $173
801059b6:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
801059bb:	e9 2c f5 ff ff       	jmp    80104eec <alltraps>

801059c0 <vector174>:
.globl vector174
vector174:
  pushl $0
801059c0:	6a 00                	push   $0x0
  pushl $174
801059c2:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
801059c7:	e9 20 f5 ff ff       	jmp    80104eec <alltraps>

801059cc <vector175>:
.globl vector175
vector175:
  pushl $0
801059cc:	6a 00                	push   $0x0
  pushl $175
801059ce:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
801059d3:	e9 14 f5 ff ff       	jmp    80104eec <alltraps>

801059d8 <vector176>:
.globl vector176
vector176:
  pushl $0
801059d8:	6a 00                	push   $0x0
  pushl $176
801059da:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
801059df:	e9 08 f5 ff ff       	jmp    80104eec <alltraps>

801059e4 <vector177>:
.globl vector177
vector177:
  pushl $0
801059e4:	6a 00                	push   $0x0
  pushl $177
801059e6:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
801059eb:	e9 fc f4 ff ff       	jmp    80104eec <alltraps>

801059f0 <vector178>:
.globl vector178
vector178:
  pushl $0
801059f0:	6a 00                	push   $0x0
  pushl $178
801059f2:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
801059f7:	e9 f0 f4 ff ff       	jmp    80104eec <alltraps>

801059fc <vector179>:
.globl vector179
vector179:
  pushl $0
801059fc:	6a 00                	push   $0x0
  pushl $179
801059fe:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80105a03:	e9 e4 f4 ff ff       	jmp    80104eec <alltraps>

80105a08 <vector180>:
.globl vector180
vector180:
  pushl $0
80105a08:	6a 00                	push   $0x0
  pushl $180
80105a0a:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80105a0f:	e9 d8 f4 ff ff       	jmp    80104eec <alltraps>

80105a14 <vector181>:
.globl vector181
vector181:
  pushl $0
80105a14:	6a 00                	push   $0x0
  pushl $181
80105a16:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80105a1b:	e9 cc f4 ff ff       	jmp    80104eec <alltraps>

80105a20 <vector182>:
.globl vector182
vector182:
  pushl $0
80105a20:	6a 00                	push   $0x0
  pushl $182
80105a22:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80105a27:	e9 c0 f4 ff ff       	jmp    80104eec <alltraps>

80105a2c <vector183>:
.globl vector183
vector183:
  pushl $0
80105a2c:	6a 00                	push   $0x0
  pushl $183
80105a2e:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80105a33:	e9 b4 f4 ff ff       	jmp    80104eec <alltraps>

80105a38 <vector184>:
.globl vector184
vector184:
  pushl $0
80105a38:	6a 00                	push   $0x0
  pushl $184
80105a3a:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80105a3f:	e9 a8 f4 ff ff       	jmp    80104eec <alltraps>

80105a44 <vector185>:
.globl vector185
vector185:
  pushl $0
80105a44:	6a 00                	push   $0x0
  pushl $185
80105a46:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80105a4b:	e9 9c f4 ff ff       	jmp    80104eec <alltraps>

80105a50 <vector186>:
.globl vector186
vector186:
  pushl $0
80105a50:	6a 00                	push   $0x0
  pushl $186
80105a52:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80105a57:	e9 90 f4 ff ff       	jmp    80104eec <alltraps>

80105a5c <vector187>:
.globl vector187
vector187:
  pushl $0
80105a5c:	6a 00                	push   $0x0
  pushl $187
80105a5e:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80105a63:	e9 84 f4 ff ff       	jmp    80104eec <alltraps>

80105a68 <vector188>:
.globl vector188
vector188:
  pushl $0
80105a68:	6a 00                	push   $0x0
  pushl $188
80105a6a:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80105a6f:	e9 78 f4 ff ff       	jmp    80104eec <alltraps>

80105a74 <vector189>:
.globl vector189
vector189:
  pushl $0
80105a74:	6a 00                	push   $0x0
  pushl $189
80105a76:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80105a7b:	e9 6c f4 ff ff       	jmp    80104eec <alltraps>

80105a80 <vector190>:
.globl vector190
vector190:
  pushl $0
80105a80:	6a 00                	push   $0x0
  pushl $190
80105a82:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80105a87:	e9 60 f4 ff ff       	jmp    80104eec <alltraps>

80105a8c <vector191>:
.globl vector191
vector191:
  pushl $0
80105a8c:	6a 00                	push   $0x0
  pushl $191
80105a8e:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80105a93:	e9 54 f4 ff ff       	jmp    80104eec <alltraps>

80105a98 <vector192>:
.globl vector192
vector192:
  pushl $0
80105a98:	6a 00                	push   $0x0
  pushl $192
80105a9a:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80105a9f:	e9 48 f4 ff ff       	jmp    80104eec <alltraps>

80105aa4 <vector193>:
.globl vector193
vector193:
  pushl $0
80105aa4:	6a 00                	push   $0x0
  pushl $193
80105aa6:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80105aab:	e9 3c f4 ff ff       	jmp    80104eec <alltraps>

80105ab0 <vector194>:
.globl vector194
vector194:
  pushl $0
80105ab0:	6a 00                	push   $0x0
  pushl $194
80105ab2:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80105ab7:	e9 30 f4 ff ff       	jmp    80104eec <alltraps>

80105abc <vector195>:
.globl vector195
vector195:
  pushl $0
80105abc:	6a 00                	push   $0x0
  pushl $195
80105abe:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80105ac3:	e9 24 f4 ff ff       	jmp    80104eec <alltraps>

80105ac8 <vector196>:
.globl vector196
vector196:
  pushl $0
80105ac8:	6a 00                	push   $0x0
  pushl $196
80105aca:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80105acf:	e9 18 f4 ff ff       	jmp    80104eec <alltraps>

80105ad4 <vector197>:
.globl vector197
vector197:
  pushl $0
80105ad4:	6a 00                	push   $0x0
  pushl $197
80105ad6:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80105adb:	e9 0c f4 ff ff       	jmp    80104eec <alltraps>

80105ae0 <vector198>:
.globl vector198
vector198:
  pushl $0
80105ae0:	6a 00                	push   $0x0
  pushl $198
80105ae2:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80105ae7:	e9 00 f4 ff ff       	jmp    80104eec <alltraps>

80105aec <vector199>:
.globl vector199
vector199:
  pushl $0
80105aec:	6a 00                	push   $0x0
  pushl $199
80105aee:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80105af3:	e9 f4 f3 ff ff       	jmp    80104eec <alltraps>

80105af8 <vector200>:
.globl vector200
vector200:
  pushl $0
80105af8:	6a 00                	push   $0x0
  pushl $200
80105afa:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80105aff:	e9 e8 f3 ff ff       	jmp    80104eec <alltraps>

80105b04 <vector201>:
.globl vector201
vector201:
  pushl $0
80105b04:	6a 00                	push   $0x0
  pushl $201
80105b06:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80105b0b:	e9 dc f3 ff ff       	jmp    80104eec <alltraps>

80105b10 <vector202>:
.globl vector202
vector202:
  pushl $0
80105b10:	6a 00                	push   $0x0
  pushl $202
80105b12:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80105b17:	e9 d0 f3 ff ff       	jmp    80104eec <alltraps>

80105b1c <vector203>:
.globl vector203
vector203:
  pushl $0
80105b1c:	6a 00                	push   $0x0
  pushl $203
80105b1e:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80105b23:	e9 c4 f3 ff ff       	jmp    80104eec <alltraps>

80105b28 <vector204>:
.globl vector204
vector204:
  pushl $0
80105b28:	6a 00                	push   $0x0
  pushl $204
80105b2a:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80105b2f:	e9 b8 f3 ff ff       	jmp    80104eec <alltraps>

80105b34 <vector205>:
.globl vector205
vector205:
  pushl $0
80105b34:	6a 00                	push   $0x0
  pushl $205
80105b36:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80105b3b:	e9 ac f3 ff ff       	jmp    80104eec <alltraps>

80105b40 <vector206>:
.globl vector206
vector206:
  pushl $0
80105b40:	6a 00                	push   $0x0
  pushl $206
80105b42:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80105b47:	e9 a0 f3 ff ff       	jmp    80104eec <alltraps>

80105b4c <vector207>:
.globl vector207
vector207:
  pushl $0
80105b4c:	6a 00                	push   $0x0
  pushl $207
80105b4e:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80105b53:	e9 94 f3 ff ff       	jmp    80104eec <alltraps>

80105b58 <vector208>:
.globl vector208
vector208:
  pushl $0
80105b58:	6a 00                	push   $0x0
  pushl $208
80105b5a:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80105b5f:	e9 88 f3 ff ff       	jmp    80104eec <alltraps>

80105b64 <vector209>:
.globl vector209
vector209:
  pushl $0
80105b64:	6a 00                	push   $0x0
  pushl $209
80105b66:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80105b6b:	e9 7c f3 ff ff       	jmp    80104eec <alltraps>

80105b70 <vector210>:
.globl vector210
vector210:
  pushl $0
80105b70:	6a 00                	push   $0x0
  pushl $210
80105b72:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80105b77:	e9 70 f3 ff ff       	jmp    80104eec <alltraps>

80105b7c <vector211>:
.globl vector211
vector211:
  pushl $0
80105b7c:	6a 00                	push   $0x0
  pushl $211
80105b7e:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80105b83:	e9 64 f3 ff ff       	jmp    80104eec <alltraps>

80105b88 <vector212>:
.globl vector212
vector212:
  pushl $0
80105b88:	6a 00                	push   $0x0
  pushl $212
80105b8a:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80105b8f:	e9 58 f3 ff ff       	jmp    80104eec <alltraps>

80105b94 <vector213>:
.globl vector213
vector213:
  pushl $0
80105b94:	6a 00                	push   $0x0
  pushl $213
80105b96:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80105b9b:	e9 4c f3 ff ff       	jmp    80104eec <alltraps>

80105ba0 <vector214>:
.globl vector214
vector214:
  pushl $0
80105ba0:	6a 00                	push   $0x0
  pushl $214
80105ba2:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80105ba7:	e9 40 f3 ff ff       	jmp    80104eec <alltraps>

80105bac <vector215>:
.globl vector215
vector215:
  pushl $0
80105bac:	6a 00                	push   $0x0
  pushl $215
80105bae:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80105bb3:	e9 34 f3 ff ff       	jmp    80104eec <alltraps>

80105bb8 <vector216>:
.globl vector216
vector216:
  pushl $0
80105bb8:	6a 00                	push   $0x0
  pushl $216
80105bba:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80105bbf:	e9 28 f3 ff ff       	jmp    80104eec <alltraps>

80105bc4 <vector217>:
.globl vector217
vector217:
  pushl $0
80105bc4:	6a 00                	push   $0x0
  pushl $217
80105bc6:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80105bcb:	e9 1c f3 ff ff       	jmp    80104eec <alltraps>

80105bd0 <vector218>:
.globl vector218
vector218:
  pushl $0
80105bd0:	6a 00                	push   $0x0
  pushl $218
80105bd2:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80105bd7:	e9 10 f3 ff ff       	jmp    80104eec <alltraps>

80105bdc <vector219>:
.globl vector219
vector219:
  pushl $0
80105bdc:	6a 00                	push   $0x0
  pushl $219
80105bde:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80105be3:	e9 04 f3 ff ff       	jmp    80104eec <alltraps>

80105be8 <vector220>:
.globl vector220
vector220:
  pushl $0
80105be8:	6a 00                	push   $0x0
  pushl $220
80105bea:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80105bef:	e9 f8 f2 ff ff       	jmp    80104eec <alltraps>

80105bf4 <vector221>:
.globl vector221
vector221:
  pushl $0
80105bf4:	6a 00                	push   $0x0
  pushl $221
80105bf6:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80105bfb:	e9 ec f2 ff ff       	jmp    80104eec <alltraps>

80105c00 <vector222>:
.globl vector222
vector222:
  pushl $0
80105c00:	6a 00                	push   $0x0
  pushl $222
80105c02:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80105c07:	e9 e0 f2 ff ff       	jmp    80104eec <alltraps>

80105c0c <vector223>:
.globl vector223
vector223:
  pushl $0
80105c0c:	6a 00                	push   $0x0
  pushl $223
80105c0e:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80105c13:	e9 d4 f2 ff ff       	jmp    80104eec <alltraps>

80105c18 <vector224>:
.globl vector224
vector224:
  pushl $0
80105c18:	6a 00                	push   $0x0
  pushl $224
80105c1a:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80105c1f:	e9 c8 f2 ff ff       	jmp    80104eec <alltraps>

80105c24 <vector225>:
.globl vector225
vector225:
  pushl $0
80105c24:	6a 00                	push   $0x0
  pushl $225
80105c26:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80105c2b:	e9 bc f2 ff ff       	jmp    80104eec <alltraps>

80105c30 <vector226>:
.globl vector226
vector226:
  pushl $0
80105c30:	6a 00                	push   $0x0
  pushl $226
80105c32:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80105c37:	e9 b0 f2 ff ff       	jmp    80104eec <alltraps>

80105c3c <vector227>:
.globl vector227
vector227:
  pushl $0
80105c3c:	6a 00                	push   $0x0
  pushl $227
80105c3e:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80105c43:	e9 a4 f2 ff ff       	jmp    80104eec <alltraps>

80105c48 <vector228>:
.globl vector228
vector228:
  pushl $0
80105c48:	6a 00                	push   $0x0
  pushl $228
80105c4a:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80105c4f:	e9 98 f2 ff ff       	jmp    80104eec <alltraps>

80105c54 <vector229>:
.globl vector229
vector229:
  pushl $0
80105c54:	6a 00                	push   $0x0
  pushl $229
80105c56:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80105c5b:	e9 8c f2 ff ff       	jmp    80104eec <alltraps>

80105c60 <vector230>:
.globl vector230
vector230:
  pushl $0
80105c60:	6a 00                	push   $0x0
  pushl $230
80105c62:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80105c67:	e9 80 f2 ff ff       	jmp    80104eec <alltraps>

80105c6c <vector231>:
.globl vector231
vector231:
  pushl $0
80105c6c:	6a 00                	push   $0x0
  pushl $231
80105c6e:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80105c73:	e9 74 f2 ff ff       	jmp    80104eec <alltraps>

80105c78 <vector232>:
.globl vector232
vector232:
  pushl $0
80105c78:	6a 00                	push   $0x0
  pushl $232
80105c7a:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80105c7f:	e9 68 f2 ff ff       	jmp    80104eec <alltraps>

80105c84 <vector233>:
.globl vector233
vector233:
  pushl $0
80105c84:	6a 00                	push   $0x0
  pushl $233
80105c86:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80105c8b:	e9 5c f2 ff ff       	jmp    80104eec <alltraps>

80105c90 <vector234>:
.globl vector234
vector234:
  pushl $0
80105c90:	6a 00                	push   $0x0
  pushl $234
80105c92:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80105c97:	e9 50 f2 ff ff       	jmp    80104eec <alltraps>

80105c9c <vector235>:
.globl vector235
vector235:
  pushl $0
80105c9c:	6a 00                	push   $0x0
  pushl $235
80105c9e:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80105ca3:	e9 44 f2 ff ff       	jmp    80104eec <alltraps>

80105ca8 <vector236>:
.globl vector236
vector236:
  pushl $0
80105ca8:	6a 00                	push   $0x0
  pushl $236
80105caa:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80105caf:	e9 38 f2 ff ff       	jmp    80104eec <alltraps>

80105cb4 <vector237>:
.globl vector237
vector237:
  pushl $0
80105cb4:	6a 00                	push   $0x0
  pushl $237
80105cb6:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80105cbb:	e9 2c f2 ff ff       	jmp    80104eec <alltraps>

80105cc0 <vector238>:
.globl vector238
vector238:
  pushl $0
80105cc0:	6a 00                	push   $0x0
  pushl $238
80105cc2:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80105cc7:	e9 20 f2 ff ff       	jmp    80104eec <alltraps>

80105ccc <vector239>:
.globl vector239
vector239:
  pushl $0
80105ccc:	6a 00                	push   $0x0
  pushl $239
80105cce:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80105cd3:	e9 14 f2 ff ff       	jmp    80104eec <alltraps>

80105cd8 <vector240>:
.globl vector240
vector240:
  pushl $0
80105cd8:	6a 00                	push   $0x0
  pushl $240
80105cda:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80105cdf:	e9 08 f2 ff ff       	jmp    80104eec <alltraps>

80105ce4 <vector241>:
.globl vector241
vector241:
  pushl $0
80105ce4:	6a 00                	push   $0x0
  pushl $241
80105ce6:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80105ceb:	e9 fc f1 ff ff       	jmp    80104eec <alltraps>

80105cf0 <vector242>:
.globl vector242
vector242:
  pushl $0
80105cf0:	6a 00                	push   $0x0
  pushl $242
80105cf2:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80105cf7:	e9 f0 f1 ff ff       	jmp    80104eec <alltraps>

80105cfc <vector243>:
.globl vector243
vector243:
  pushl $0
80105cfc:	6a 00                	push   $0x0
  pushl $243
80105cfe:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80105d03:	e9 e4 f1 ff ff       	jmp    80104eec <alltraps>

80105d08 <vector244>:
.globl vector244
vector244:
  pushl $0
80105d08:	6a 00                	push   $0x0
  pushl $244
80105d0a:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80105d0f:	e9 d8 f1 ff ff       	jmp    80104eec <alltraps>

80105d14 <vector245>:
.globl vector245
vector245:
  pushl $0
80105d14:	6a 00                	push   $0x0
  pushl $245
80105d16:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80105d1b:	e9 cc f1 ff ff       	jmp    80104eec <alltraps>

80105d20 <vector246>:
.globl vector246
vector246:
  pushl $0
80105d20:	6a 00                	push   $0x0
  pushl $246
80105d22:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80105d27:	e9 c0 f1 ff ff       	jmp    80104eec <alltraps>

80105d2c <vector247>:
.globl vector247
vector247:
  pushl $0
80105d2c:	6a 00                	push   $0x0
  pushl $247
80105d2e:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80105d33:	e9 b4 f1 ff ff       	jmp    80104eec <alltraps>

80105d38 <vector248>:
.globl vector248
vector248:
  pushl $0
80105d38:	6a 00                	push   $0x0
  pushl $248
80105d3a:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80105d3f:	e9 a8 f1 ff ff       	jmp    80104eec <alltraps>

80105d44 <vector249>:
.globl vector249
vector249:
  pushl $0
80105d44:	6a 00                	push   $0x0
  pushl $249
80105d46:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80105d4b:	e9 9c f1 ff ff       	jmp    80104eec <alltraps>

80105d50 <vector250>:
.globl vector250
vector250:
  pushl $0
80105d50:	6a 00                	push   $0x0
  pushl $250
80105d52:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80105d57:	e9 90 f1 ff ff       	jmp    80104eec <alltraps>

80105d5c <vector251>:
.globl vector251
vector251:
  pushl $0
80105d5c:	6a 00                	push   $0x0
  pushl $251
80105d5e:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80105d63:	e9 84 f1 ff ff       	jmp    80104eec <alltraps>

80105d68 <vector252>:
.globl vector252
vector252:
  pushl $0
80105d68:	6a 00                	push   $0x0
  pushl $252
80105d6a:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80105d6f:	e9 78 f1 ff ff       	jmp    80104eec <alltraps>

80105d74 <vector253>:
.globl vector253
vector253:
  pushl $0
80105d74:	6a 00                	push   $0x0
  pushl $253
80105d76:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80105d7b:	e9 6c f1 ff ff       	jmp    80104eec <alltraps>

80105d80 <vector254>:
.globl vector254
vector254:
  pushl $0
80105d80:	6a 00                	push   $0x0
  pushl $254
80105d82:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80105d87:	e9 60 f1 ff ff       	jmp    80104eec <alltraps>

80105d8c <vector255>:
.globl vector255
vector255:
  pushl $0
80105d8c:	6a 00                	push   $0x0
  pushl $255
80105d8e:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80105d93:	e9 54 f1 ff ff       	jmp    80104eec <alltraps>

80105d98 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80105d98:	55                   	push   %ebp
80105d99:	89 e5                	mov    %esp,%ebp
80105d9b:	57                   	push   %edi
80105d9c:	56                   	push   %esi
80105d9d:	53                   	push   %ebx
80105d9e:	83 ec 0c             	sub    $0xc,%esp
80105da1:	89 d3                	mov    %edx,%ebx
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80105da3:	c1 ea 16             	shr    $0x16,%edx
80105da6:	8d 3c 90             	lea    (%eax,%edx,4),%edi
  if(*pde & PTE_P){
80105da9:	8b 37                	mov    (%edi),%esi
80105dab:	f7 c6 01 00 00 00    	test   $0x1,%esi
80105db1:	74 20                	je     80105dd3 <walkpgdir+0x3b>
    pgtab = (pte_t*)P2V(PTE_ADDR(*pde));
80105db3:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
80105db9:	81 c6 00 00 00 80    	add    $0x80000000,%esi
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table
    // entries, if necessary.
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
  }
  return &pgtab[PTX(va)];
80105dbf:	c1 eb 0c             	shr    $0xc,%ebx
80105dc2:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
80105dc8:	8d 04 9e             	lea    (%esi,%ebx,4),%eax
}
80105dcb:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105dce:	5b                   	pop    %ebx
80105dcf:	5e                   	pop    %esi
80105dd0:	5f                   	pop    %edi
80105dd1:	5d                   	pop    %ebp
80105dd2:	c3                   	ret    
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80105dd3:	85 c9                	test   %ecx,%ecx
80105dd5:	74 2b                	je     80105e02 <walkpgdir+0x6a>
80105dd7:	e8 b3 c3 ff ff       	call   8010218f <kalloc>
80105ddc:	89 c6                	mov    %eax,%esi
80105dde:	85 c0                	test   %eax,%eax
80105de0:	74 20                	je     80105e02 <walkpgdir+0x6a>
    memset(pgtab, 0, PGSIZE);
80105de2:	83 ec 04             	sub    $0x4,%esp
80105de5:	68 00 10 00 00       	push   $0x1000
80105dea:	6a 00                	push   $0x0
80105dec:	50                   	push   %eax
80105ded:	e8 2f e0 ff ff       	call   80103e21 <memset>
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
80105df2:	8d 86 00 00 00 80    	lea    -0x80000000(%esi),%eax
80105df8:	83 c8 07             	or     $0x7,%eax
80105dfb:	89 07                	mov    %eax,(%edi)
80105dfd:	83 c4 10             	add    $0x10,%esp
80105e00:	eb bd                	jmp    80105dbf <walkpgdir+0x27>
      return 0;
80105e02:	b8 00 00 00 00       	mov    $0x0,%eax
80105e07:	eb c2                	jmp    80105dcb <walkpgdir+0x33>

80105e09 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80105e09:	55                   	push   %ebp
80105e0a:	89 e5                	mov    %esp,%ebp
80105e0c:	57                   	push   %edi
80105e0d:	56                   	push   %esi
80105e0e:	53                   	push   %ebx
80105e0f:	83 ec 1c             	sub    $0x1c,%esp
80105e12:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105e15:	8b 75 08             	mov    0x8(%ebp),%esi
  char *a, *last;
  pte_t *pte;

  a = (char*)PGROUNDDOWN((uint)va);
80105e18:	89 d3                	mov    %edx,%ebx
80105e1a:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80105e20:	8d 7c 0a ff          	lea    -0x1(%edx,%ecx,1),%edi
80105e24:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105e2a:	b9 01 00 00 00       	mov    $0x1,%ecx
80105e2f:	89 da                	mov    %ebx,%edx
80105e31:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105e34:	e8 5f ff ff ff       	call   80105d98 <walkpgdir>
80105e39:	85 c0                	test   %eax,%eax
80105e3b:	74 2e                	je     80105e6b <mappages+0x62>
      return -1;
    if(*pte & PTE_P)
80105e3d:	f6 00 01             	testb  $0x1,(%eax)
80105e40:	75 1c                	jne    80105e5e <mappages+0x55>
      panic("remap");
    *pte = pa | perm | PTE_P;
80105e42:	89 f2                	mov    %esi,%edx
80105e44:	0b 55 0c             	or     0xc(%ebp),%edx
80105e47:	83 ca 01             	or     $0x1,%edx
80105e4a:	89 10                	mov    %edx,(%eax)
    if(a == last)
80105e4c:	39 fb                	cmp    %edi,%ebx
80105e4e:	74 28                	je     80105e78 <mappages+0x6f>
      break;
    a += PGSIZE;
80105e50:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    pa += PGSIZE;
80105e56:	81 c6 00 10 00 00    	add    $0x1000,%esi
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105e5c:	eb cc                	jmp    80105e2a <mappages+0x21>
      panic("remap");
80105e5e:	83 ec 0c             	sub    $0xc,%esp
80105e61:	68 4c 6f 10 80       	push   $0x80106f4c
80105e66:	e8 f1 a4 ff ff       	call   8010035c <panic>
      return -1;
80105e6b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  return 0;
}
80105e70:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105e73:	5b                   	pop    %ebx
80105e74:	5e                   	pop    %esi
80105e75:	5f                   	pop    %edi
80105e76:	5d                   	pop    %ebp
80105e77:	c3                   	ret    
  return 0;
80105e78:	b8 00 00 00 00       	mov    $0x0,%eax
80105e7d:	eb f1                	jmp    80105e70 <mappages+0x67>

80105e7f <seginit>:
{
80105e7f:	f3 0f 1e fb          	endbr32 
80105e83:	55                   	push   %ebp
80105e84:	89 e5                	mov    %esp,%ebp
80105e86:	53                   	push   %ebx
80105e87:	83 ec 14             	sub    $0x14,%esp
  c = &cpus[cpuid()];
80105e8a:	e8 6c d4 ff ff       	call   801032fb <cpuid>
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80105e8f:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
80105e95:	66 c7 80 58 48 11 80 	movw   $0xffff,-0x7feeb7a8(%eax)
80105e9c:	ff ff 
80105e9e:	66 c7 80 5a 48 11 80 	movw   $0x0,-0x7feeb7a6(%eax)
80105ea5:	00 00 
80105ea7:	c6 80 5c 48 11 80 00 	movb   $0x0,-0x7feeb7a4(%eax)
80105eae:	0f b6 88 5d 48 11 80 	movzbl -0x7feeb7a3(%eax),%ecx
80105eb5:	83 e1 f0             	and    $0xfffffff0,%ecx
80105eb8:	83 c9 1a             	or     $0x1a,%ecx
80105ebb:	83 e1 9f             	and    $0xffffff9f,%ecx
80105ebe:	83 c9 80             	or     $0xffffff80,%ecx
80105ec1:	88 88 5d 48 11 80    	mov    %cl,-0x7feeb7a3(%eax)
80105ec7:	0f b6 88 5e 48 11 80 	movzbl -0x7feeb7a2(%eax),%ecx
80105ece:	83 c9 0f             	or     $0xf,%ecx
80105ed1:	83 e1 cf             	and    $0xffffffcf,%ecx
80105ed4:	83 c9 c0             	or     $0xffffffc0,%ecx
80105ed7:	88 88 5e 48 11 80    	mov    %cl,-0x7feeb7a2(%eax)
80105edd:	c6 80 5f 48 11 80 00 	movb   $0x0,-0x7feeb7a1(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80105ee4:	66 c7 80 60 48 11 80 	movw   $0xffff,-0x7feeb7a0(%eax)
80105eeb:	ff ff 
80105eed:	66 c7 80 62 48 11 80 	movw   $0x0,-0x7feeb79e(%eax)
80105ef4:	00 00 
80105ef6:	c6 80 64 48 11 80 00 	movb   $0x0,-0x7feeb79c(%eax)
80105efd:	0f b6 88 65 48 11 80 	movzbl -0x7feeb79b(%eax),%ecx
80105f04:	83 e1 f0             	and    $0xfffffff0,%ecx
80105f07:	83 c9 12             	or     $0x12,%ecx
80105f0a:	83 e1 9f             	and    $0xffffff9f,%ecx
80105f0d:	83 c9 80             	or     $0xffffff80,%ecx
80105f10:	88 88 65 48 11 80    	mov    %cl,-0x7feeb79b(%eax)
80105f16:	0f b6 88 66 48 11 80 	movzbl -0x7feeb79a(%eax),%ecx
80105f1d:	83 c9 0f             	or     $0xf,%ecx
80105f20:	83 e1 cf             	and    $0xffffffcf,%ecx
80105f23:	83 c9 c0             	or     $0xffffffc0,%ecx
80105f26:	88 88 66 48 11 80    	mov    %cl,-0x7feeb79a(%eax)
80105f2c:	c6 80 67 48 11 80 00 	movb   $0x0,-0x7feeb799(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80105f33:	66 c7 80 68 48 11 80 	movw   $0xffff,-0x7feeb798(%eax)
80105f3a:	ff ff 
80105f3c:	66 c7 80 6a 48 11 80 	movw   $0x0,-0x7feeb796(%eax)
80105f43:	00 00 
80105f45:	c6 80 6c 48 11 80 00 	movb   $0x0,-0x7feeb794(%eax)
80105f4c:	c6 80 6d 48 11 80 fa 	movb   $0xfa,-0x7feeb793(%eax)
80105f53:	0f b6 88 6e 48 11 80 	movzbl -0x7feeb792(%eax),%ecx
80105f5a:	83 c9 0f             	or     $0xf,%ecx
80105f5d:	83 e1 cf             	and    $0xffffffcf,%ecx
80105f60:	83 c9 c0             	or     $0xffffffc0,%ecx
80105f63:	88 88 6e 48 11 80    	mov    %cl,-0x7feeb792(%eax)
80105f69:	c6 80 6f 48 11 80 00 	movb   $0x0,-0x7feeb791(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80105f70:	66 c7 80 70 48 11 80 	movw   $0xffff,-0x7feeb790(%eax)
80105f77:	ff ff 
80105f79:	66 c7 80 72 48 11 80 	movw   $0x0,-0x7feeb78e(%eax)
80105f80:	00 00 
80105f82:	c6 80 74 48 11 80 00 	movb   $0x0,-0x7feeb78c(%eax)
80105f89:	c6 80 75 48 11 80 f2 	movb   $0xf2,-0x7feeb78b(%eax)
80105f90:	0f b6 88 76 48 11 80 	movzbl -0x7feeb78a(%eax),%ecx
80105f97:	83 c9 0f             	or     $0xf,%ecx
80105f9a:	83 e1 cf             	and    $0xffffffcf,%ecx
80105f9d:	83 c9 c0             	or     $0xffffffc0,%ecx
80105fa0:	88 88 76 48 11 80    	mov    %cl,-0x7feeb78a(%eax)
80105fa6:	c6 80 77 48 11 80 00 	movb   $0x0,-0x7feeb789(%eax)
  lgdt(c->gdt, sizeof(c->gdt));
80105fad:	05 50 48 11 80       	add    $0x80114850,%eax
  pd[0] = size-1;
80105fb2:	66 c7 45 f2 2f 00    	movw   $0x2f,-0xe(%ebp)
  pd[1] = (uint)p;
80105fb8:	66 89 45 f4          	mov    %ax,-0xc(%ebp)
  pd[2] = (uint)p >> 16;
80105fbc:	c1 e8 10             	shr    $0x10,%eax
80105fbf:	66 89 45 f6          	mov    %ax,-0xa(%ebp)
  asm volatile("lgdt (%0)" : : "r" (pd));
80105fc3:	8d 45 f2             	lea    -0xe(%ebp),%eax
80105fc6:	0f 01 10             	lgdtl  (%eax)
}
80105fc9:	83 c4 14             	add    $0x14,%esp
80105fcc:	5b                   	pop    %ebx
80105fcd:	5d                   	pop    %ebp
80105fce:	c3                   	ret    

80105fcf <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80105fcf:	f3 0f 1e fb          	endbr32 
  lcr3(V2P(kpgdir));   // switch to the kernel page table
80105fd3:	a1 84 55 11 80       	mov    0x80115584,%eax
80105fd8:	05 00 00 00 80       	add    $0x80000000,%eax
}

static inline void
lcr3(uint val)
{
  asm volatile("movl %0,%%cr3" : : "r" (val));
80105fdd:	0f 22 d8             	mov    %eax,%cr3
}
80105fe0:	c3                   	ret    

80105fe1 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80105fe1:	f3 0f 1e fb          	endbr32 
80105fe5:	55                   	push   %ebp
80105fe6:	89 e5                	mov    %esp,%ebp
80105fe8:	57                   	push   %edi
80105fe9:	56                   	push   %esi
80105fea:	53                   	push   %ebx
80105feb:	83 ec 1c             	sub    $0x1c,%esp
80105fee:	8b 75 08             	mov    0x8(%ebp),%esi
  if(p == 0)
80105ff1:	85 f6                	test   %esi,%esi
80105ff3:	0f 84 dd 00 00 00    	je     801060d6 <switchuvm+0xf5>
    panic("switchuvm: no process");
  if(p->kstack == 0)
80105ff9:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
80105ffd:	0f 84 e0 00 00 00    	je     801060e3 <switchuvm+0x102>
    panic("switchuvm: no kstack");
  if(p->pgdir == 0)
80106003:	83 7e 04 00          	cmpl   $0x0,0x4(%esi)
80106007:	0f 84 e3 00 00 00    	je     801060f0 <switchuvm+0x10f>
    panic("switchuvm: no pgdir");

  pushcli();
8010600d:	e8 72 dc ff ff       	call   80103c84 <pushcli>
  mycpu()->gdt[SEG_TSS] = SEG16(STS_T32A, &mycpu()->ts,
80106012:	e8 84 d2 ff ff       	call   8010329b <mycpu>
80106017:	89 c3                	mov    %eax,%ebx
80106019:	e8 7d d2 ff ff       	call   8010329b <mycpu>
8010601e:	8d 78 08             	lea    0x8(%eax),%edi
80106021:	e8 75 d2 ff ff       	call   8010329b <mycpu>
80106026:	83 c0 08             	add    $0x8,%eax
80106029:	c1 e8 10             	shr    $0x10,%eax
8010602c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010602f:	e8 67 d2 ff ff       	call   8010329b <mycpu>
80106034:	83 c0 08             	add    $0x8,%eax
80106037:	c1 e8 18             	shr    $0x18,%eax
8010603a:	66 c7 83 98 00 00 00 	movw   $0x67,0x98(%ebx)
80106041:	67 00 
80106043:	66 89 bb 9a 00 00 00 	mov    %di,0x9a(%ebx)
8010604a:	0f b6 4d e4          	movzbl -0x1c(%ebp),%ecx
8010604e:	88 8b 9c 00 00 00    	mov    %cl,0x9c(%ebx)
80106054:	0f b6 93 9d 00 00 00 	movzbl 0x9d(%ebx),%edx
8010605b:	83 e2 f0             	and    $0xfffffff0,%edx
8010605e:	83 ca 19             	or     $0x19,%edx
80106061:	83 e2 9f             	and    $0xffffff9f,%edx
80106064:	83 ca 80             	or     $0xffffff80,%edx
80106067:	88 93 9d 00 00 00    	mov    %dl,0x9d(%ebx)
8010606d:	c6 83 9e 00 00 00 40 	movb   $0x40,0x9e(%ebx)
80106074:	88 83 9f 00 00 00    	mov    %al,0x9f(%ebx)
                                sizeof(mycpu()->ts)-1, 0);
  mycpu()->gdt[SEG_TSS].s = 0;
8010607a:	e8 1c d2 ff ff       	call   8010329b <mycpu>
8010607f:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80106086:	83 e2 ef             	and    $0xffffffef,%edx
80106089:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
  mycpu()->ts.ss0 = SEG_KDATA << 3;
8010608f:	e8 07 d2 ff ff       	call   8010329b <mycpu>
80106094:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  mycpu()->ts.esp0 = (uint)p->kstack + KSTACKSIZE;
8010609a:	8b 5e 08             	mov    0x8(%esi),%ebx
8010609d:	e8 f9 d1 ff ff       	call   8010329b <mycpu>
801060a2:	81 c3 00 10 00 00    	add    $0x1000,%ebx
801060a8:	89 58 0c             	mov    %ebx,0xc(%eax)
  // setting IOPL=0 in eflags *and* iomb beyond the tss segment limit
  // forbids I/O instructions (e.g., inb and outb) from user space
  mycpu()->ts.iomb = (ushort) 0xFFFF;
801060ab:	e8 eb d1 ff ff       	call   8010329b <mycpu>
801060b0:	66 c7 40 6e ff ff    	movw   $0xffff,0x6e(%eax)
  asm volatile("ltr %0" : : "r" (sel));
801060b6:	b8 28 00 00 00       	mov    $0x28,%eax
801060bb:	0f 00 d8             	ltr    %ax
  ltr(SEG_TSS << 3);
  lcr3(V2P(p->pgdir));  // switch to process's address space
801060be:	8b 46 04             	mov    0x4(%esi),%eax
801060c1:	05 00 00 00 80       	add    $0x80000000,%eax
  asm volatile("movl %0,%%cr3" : : "r" (val));
801060c6:	0f 22 d8             	mov    %eax,%cr3
  popcli();
801060c9:	e8 f7 db ff ff       	call   80103cc5 <popcli>
}
801060ce:	8d 65 f4             	lea    -0xc(%ebp),%esp
801060d1:	5b                   	pop    %ebx
801060d2:	5e                   	pop    %esi
801060d3:	5f                   	pop    %edi
801060d4:	5d                   	pop    %ebp
801060d5:	c3                   	ret    
    panic("switchuvm: no process");
801060d6:	83 ec 0c             	sub    $0xc,%esp
801060d9:	68 52 6f 10 80       	push   $0x80106f52
801060de:	e8 79 a2 ff ff       	call   8010035c <panic>
    panic("switchuvm: no kstack");
801060e3:	83 ec 0c             	sub    $0xc,%esp
801060e6:	68 68 6f 10 80       	push   $0x80106f68
801060eb:	e8 6c a2 ff ff       	call   8010035c <panic>
    panic("switchuvm: no pgdir");
801060f0:	83 ec 0c             	sub    $0xc,%esp
801060f3:	68 7d 6f 10 80       	push   $0x80106f7d
801060f8:	e8 5f a2 ff ff       	call   8010035c <panic>

801060fd <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
801060fd:	f3 0f 1e fb          	endbr32 
80106101:	55                   	push   %ebp
80106102:	89 e5                	mov    %esp,%ebp
80106104:	56                   	push   %esi
80106105:	53                   	push   %ebx
80106106:	8b 75 10             	mov    0x10(%ebp),%esi
  char *mem;

  if(sz >= PGSIZE)
80106109:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
8010610f:	77 4c                	ja     8010615d <inituvm+0x60>
    panic("inituvm: more than a page");
  mem = kalloc();
80106111:	e8 79 c0 ff ff       	call   8010218f <kalloc>
80106116:	89 c3                	mov    %eax,%ebx
  memset(mem, 0, PGSIZE);
80106118:	83 ec 04             	sub    $0x4,%esp
8010611b:	68 00 10 00 00       	push   $0x1000
80106120:	6a 00                	push   $0x0
80106122:	50                   	push   %eax
80106123:	e8 f9 dc ff ff       	call   80103e21 <memset>
  mappages(pgdir, 0, PGSIZE, V2P(mem), PTE_W|PTE_U);
80106128:	83 c4 08             	add    $0x8,%esp
8010612b:	6a 06                	push   $0x6
8010612d:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80106133:	50                   	push   %eax
80106134:	b9 00 10 00 00       	mov    $0x1000,%ecx
80106139:	ba 00 00 00 00       	mov    $0x0,%edx
8010613e:	8b 45 08             	mov    0x8(%ebp),%eax
80106141:	e8 c3 fc ff ff       	call   80105e09 <mappages>
  memmove(mem, init, sz);
80106146:	83 c4 0c             	add    $0xc,%esp
80106149:	56                   	push   %esi
8010614a:	ff 75 0c             	pushl  0xc(%ebp)
8010614d:	53                   	push   %ebx
8010614e:	e8 4e dd ff ff       	call   80103ea1 <memmove>
}
80106153:	83 c4 10             	add    $0x10,%esp
80106156:	8d 65 f8             	lea    -0x8(%ebp),%esp
80106159:	5b                   	pop    %ebx
8010615a:	5e                   	pop    %esi
8010615b:	5d                   	pop    %ebp
8010615c:	c3                   	ret    
    panic("inituvm: more than a page");
8010615d:	83 ec 0c             	sub    $0xc,%esp
80106160:	68 91 6f 10 80       	push   $0x80106f91
80106165:	e8 f2 a1 ff ff       	call   8010035c <panic>

8010616a <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
8010616a:	f3 0f 1e fb          	endbr32 
8010616e:	55                   	push   %ebp
8010616f:	89 e5                	mov    %esp,%ebp
80106171:	57                   	push   %edi
80106172:	56                   	push   %esi
80106173:	53                   	push   %ebx
80106174:	83 ec 0c             	sub    $0xc,%esp
80106177:	8b 7d 18             	mov    0x18(%ebp),%edi
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
8010617a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
8010617d:	81 e3 ff 0f 00 00    	and    $0xfff,%ebx
80106183:	74 3c                	je     801061c1 <loaduvm+0x57>
    panic("loaduvm: addr must be page aligned");
80106185:	83 ec 0c             	sub    $0xc,%esp
80106188:	68 4c 70 10 80       	push   $0x8010704c
8010618d:	e8 ca a1 ff ff       	call   8010035c <panic>
  for(i = 0; i < sz; i += PGSIZE){
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
      panic("loaduvm: address should exist");
80106192:	83 ec 0c             	sub    $0xc,%esp
80106195:	68 ab 6f 10 80       	push   $0x80106fab
8010619a:	e8 bd a1 ff ff       	call   8010035c <panic>
    pa = PTE_ADDR(*pte);
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, P2V(pa), offset+i, n) != n)
8010619f:	05 00 00 00 80       	add    $0x80000000,%eax
801061a4:	56                   	push   %esi
801061a5:	89 da                	mov    %ebx,%edx
801061a7:	03 55 14             	add    0x14(%ebp),%edx
801061aa:	52                   	push   %edx
801061ab:	50                   	push   %eax
801061ac:	ff 75 10             	pushl  0x10(%ebp)
801061af:	e8 59 b6 ff ff       	call   8010180d <readi>
801061b4:	83 c4 10             	add    $0x10,%esp
801061b7:	39 f0                	cmp    %esi,%eax
801061b9:	75 47                	jne    80106202 <loaduvm+0x98>
  for(i = 0; i < sz; i += PGSIZE){
801061bb:	81 c3 00 10 00 00    	add    $0x1000,%ebx
801061c1:	39 fb                	cmp    %edi,%ebx
801061c3:	73 30                	jae    801061f5 <loaduvm+0x8b>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
801061c5:	89 da                	mov    %ebx,%edx
801061c7:	03 55 0c             	add    0xc(%ebp),%edx
801061ca:	b9 00 00 00 00       	mov    $0x0,%ecx
801061cf:	8b 45 08             	mov    0x8(%ebp),%eax
801061d2:	e8 c1 fb ff ff       	call   80105d98 <walkpgdir>
801061d7:	85 c0                	test   %eax,%eax
801061d9:	74 b7                	je     80106192 <loaduvm+0x28>
    pa = PTE_ADDR(*pte);
801061db:	8b 00                	mov    (%eax),%eax
801061dd:	25 00 f0 ff ff       	and    $0xfffff000,%eax
    if(sz - i < PGSIZE)
801061e2:	89 fe                	mov    %edi,%esi
801061e4:	29 de                	sub    %ebx,%esi
801061e6:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
801061ec:	76 b1                	jbe    8010619f <loaduvm+0x35>
      n = PGSIZE;
801061ee:	be 00 10 00 00       	mov    $0x1000,%esi
801061f3:	eb aa                	jmp    8010619f <loaduvm+0x35>
      return -1;
  }
  return 0;
801061f5:	b8 00 00 00 00       	mov    $0x0,%eax
}
801061fa:	8d 65 f4             	lea    -0xc(%ebp),%esp
801061fd:	5b                   	pop    %ebx
801061fe:	5e                   	pop    %esi
801061ff:	5f                   	pop    %edi
80106200:	5d                   	pop    %ebp
80106201:	c3                   	ret    
      return -1;
80106202:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106207:	eb f1                	jmp    801061fa <loaduvm+0x90>

80106209 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80106209:	f3 0f 1e fb          	endbr32 
8010620d:	55                   	push   %ebp
8010620e:	89 e5                	mov    %esp,%ebp
80106210:	57                   	push   %edi
80106211:	56                   	push   %esi
80106212:	53                   	push   %ebx
80106213:	83 ec 0c             	sub    $0xc,%esp
80106216:	8b 7d 0c             	mov    0xc(%ebp),%edi
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
80106219:	39 7d 10             	cmp    %edi,0x10(%ebp)
8010621c:	73 11                	jae    8010622f <deallocuvm+0x26>
    return oldsz;

  a = PGROUNDUP(newsz);
8010621e:	8b 45 10             	mov    0x10(%ebp),%eax
80106221:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
80106227:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a  < oldsz; a += PGSIZE){
8010622d:	eb 19                	jmp    80106248 <deallocuvm+0x3f>
    return oldsz;
8010622f:	89 f8                	mov    %edi,%eax
80106231:	eb 64                	jmp    80106297 <deallocuvm+0x8e>
    pte = walkpgdir(pgdir, (char*)a, 0);
    if(!pte)
      a = PGADDR(PDX(a) + 1, 0, 0) - PGSIZE;
80106233:	c1 eb 16             	shr    $0x16,%ebx
80106236:	83 c3 01             	add    $0x1,%ebx
80106239:	c1 e3 16             	shl    $0x16,%ebx
8010623c:	81 eb 00 10 00 00    	sub    $0x1000,%ebx
  for(; a  < oldsz; a += PGSIZE){
80106242:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106248:	39 fb                	cmp    %edi,%ebx
8010624a:	73 48                	jae    80106294 <deallocuvm+0x8b>
    pte = walkpgdir(pgdir, (char*)a, 0);
8010624c:	b9 00 00 00 00       	mov    $0x0,%ecx
80106251:	89 da                	mov    %ebx,%edx
80106253:	8b 45 08             	mov    0x8(%ebp),%eax
80106256:	e8 3d fb ff ff       	call   80105d98 <walkpgdir>
8010625b:	89 c6                	mov    %eax,%esi
    if(!pte)
8010625d:	85 c0                	test   %eax,%eax
8010625f:	74 d2                	je     80106233 <deallocuvm+0x2a>
    else if((*pte & PTE_P) != 0){
80106261:	8b 00                	mov    (%eax),%eax
80106263:	a8 01                	test   $0x1,%al
80106265:	74 db                	je     80106242 <deallocuvm+0x39>
      pa = PTE_ADDR(*pte);
      if(pa == 0)
80106267:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010626c:	74 19                	je     80106287 <deallocuvm+0x7e>
        panic("kfree");
      char *v = P2V(pa);
8010626e:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
80106273:	83 ec 0c             	sub    $0xc,%esp
80106276:	50                   	push   %eax
80106277:	e8 ec bd ff ff       	call   80102068 <kfree>
      *pte = 0;
8010627c:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
80106282:	83 c4 10             	add    $0x10,%esp
80106285:	eb bb                	jmp    80106242 <deallocuvm+0x39>
        panic("kfree");
80106287:	83 ec 0c             	sub    $0xc,%esp
8010628a:	68 ce 68 10 80       	push   $0x801068ce
8010628f:	e8 c8 a0 ff ff       	call   8010035c <panic>
    }
  }
  return newsz;
80106294:	8b 45 10             	mov    0x10(%ebp),%eax
}
80106297:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010629a:	5b                   	pop    %ebx
8010629b:	5e                   	pop    %esi
8010629c:	5f                   	pop    %edi
8010629d:	5d                   	pop    %ebp
8010629e:	c3                   	ret    

8010629f <allocuvm>:
{
8010629f:	f3 0f 1e fb          	endbr32 
801062a3:	55                   	push   %ebp
801062a4:	89 e5                	mov    %esp,%ebp
801062a6:	57                   	push   %edi
801062a7:	56                   	push   %esi
801062a8:	53                   	push   %ebx
801062a9:	83 ec 1c             	sub    $0x1c,%esp
801062ac:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(newsz >= KERNBASE)
801062af:	89 7d e4             	mov    %edi,-0x1c(%ebp)
801062b2:	85 ff                	test   %edi,%edi
801062b4:	0f 88 c0 00 00 00    	js     8010637a <allocuvm+0xdb>
  if(newsz < oldsz)
801062ba:	3b 7d 0c             	cmp    0xc(%ebp),%edi
801062bd:	72 11                	jb     801062d0 <allocuvm+0x31>
  a = PGROUNDUP(oldsz);
801062bf:	8b 45 0c             	mov    0xc(%ebp),%eax
801062c2:	8d b0 ff 0f 00 00    	lea    0xfff(%eax),%esi
801062c8:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
  for(; a < newsz; a += PGSIZE){
801062ce:	eb 39                	jmp    80106309 <allocuvm+0x6a>
    return oldsz;
801062d0:	8b 45 0c             	mov    0xc(%ebp),%eax
801062d3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801062d6:	e9 a6 00 00 00       	jmp    80106381 <allocuvm+0xe2>
      cprintf("allocuvm out of memory\n");
801062db:	83 ec 0c             	sub    $0xc,%esp
801062de:	68 c9 6f 10 80       	push   $0x80106fc9
801062e3:	e8 41 a3 ff ff       	call   80100629 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
801062e8:	83 c4 0c             	add    $0xc,%esp
801062eb:	ff 75 0c             	pushl  0xc(%ebp)
801062ee:	57                   	push   %edi
801062ef:	ff 75 08             	pushl  0x8(%ebp)
801062f2:	e8 12 ff ff ff       	call   80106209 <deallocuvm>
      return 0;
801062f7:	83 c4 10             	add    $0x10,%esp
801062fa:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80106301:	eb 7e                	jmp    80106381 <allocuvm+0xe2>
  for(; a < newsz; a += PGSIZE){
80106303:	81 c6 00 10 00 00    	add    $0x1000,%esi
80106309:	39 fe                	cmp    %edi,%esi
8010630b:	73 74                	jae    80106381 <allocuvm+0xe2>
    mem = kalloc();
8010630d:	e8 7d be ff ff       	call   8010218f <kalloc>
80106312:	89 c3                	mov    %eax,%ebx
    if(mem == 0){
80106314:	85 c0                	test   %eax,%eax
80106316:	74 c3                	je     801062db <allocuvm+0x3c>
    memset(mem, 0, PGSIZE);
80106318:	83 ec 04             	sub    $0x4,%esp
8010631b:	68 00 10 00 00       	push   $0x1000
80106320:	6a 00                	push   $0x0
80106322:	50                   	push   %eax
80106323:	e8 f9 da ff ff       	call   80103e21 <memset>
    if(mappages(pgdir, (char*)a, PGSIZE, V2P(mem), PTE_W|PTE_U) < 0){
80106328:	83 c4 08             	add    $0x8,%esp
8010632b:	6a 06                	push   $0x6
8010632d:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80106333:	50                   	push   %eax
80106334:	b9 00 10 00 00       	mov    $0x1000,%ecx
80106339:	89 f2                	mov    %esi,%edx
8010633b:	8b 45 08             	mov    0x8(%ebp),%eax
8010633e:	e8 c6 fa ff ff       	call   80105e09 <mappages>
80106343:	83 c4 10             	add    $0x10,%esp
80106346:	85 c0                	test   %eax,%eax
80106348:	79 b9                	jns    80106303 <allocuvm+0x64>
      cprintf("allocuvm out of memory (2)\n");
8010634a:	83 ec 0c             	sub    $0xc,%esp
8010634d:	68 e1 6f 10 80       	push   $0x80106fe1
80106352:	e8 d2 a2 ff ff       	call   80100629 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80106357:	83 c4 0c             	add    $0xc,%esp
8010635a:	ff 75 0c             	pushl  0xc(%ebp)
8010635d:	57                   	push   %edi
8010635e:	ff 75 08             	pushl  0x8(%ebp)
80106361:	e8 a3 fe ff ff       	call   80106209 <deallocuvm>
      kfree(mem);
80106366:	89 1c 24             	mov    %ebx,(%esp)
80106369:	e8 fa bc ff ff       	call   80102068 <kfree>
      return 0;
8010636e:	83 c4 10             	add    $0x10,%esp
80106371:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80106378:	eb 07                	jmp    80106381 <allocuvm+0xe2>
    return 0;
8010637a:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
}
80106381:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106384:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106387:	5b                   	pop    %ebx
80106388:	5e                   	pop    %esi
80106389:	5f                   	pop    %edi
8010638a:	5d                   	pop    %ebp
8010638b:	c3                   	ret    

8010638c <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
8010638c:	f3 0f 1e fb          	endbr32 
80106390:	55                   	push   %ebp
80106391:	89 e5                	mov    %esp,%ebp
80106393:	56                   	push   %esi
80106394:	53                   	push   %ebx
80106395:	8b 75 08             	mov    0x8(%ebp),%esi
  uint i;

  if(pgdir == 0)
80106398:	85 f6                	test   %esi,%esi
8010639a:	74 1a                	je     801063b6 <freevm+0x2a>
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
8010639c:	83 ec 04             	sub    $0x4,%esp
8010639f:	6a 00                	push   $0x0
801063a1:	68 00 00 00 80       	push   $0x80000000
801063a6:	56                   	push   %esi
801063a7:	e8 5d fe ff ff       	call   80106209 <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
801063ac:	83 c4 10             	add    $0x10,%esp
801063af:	bb 00 00 00 00       	mov    $0x0,%ebx
801063b4:	eb 26                	jmp    801063dc <freevm+0x50>
    panic("freevm: no pgdir");
801063b6:	83 ec 0c             	sub    $0xc,%esp
801063b9:	68 fd 6f 10 80       	push   $0x80106ffd
801063be:	e8 99 9f ff ff       	call   8010035c <panic>
    if(pgdir[i] & PTE_P){
      char * v = P2V(PTE_ADDR(pgdir[i]));
801063c3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801063c8:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
801063cd:	83 ec 0c             	sub    $0xc,%esp
801063d0:	50                   	push   %eax
801063d1:	e8 92 bc ff ff       	call   80102068 <kfree>
801063d6:	83 c4 10             	add    $0x10,%esp
  for(i = 0; i < NPDENTRIES; i++){
801063d9:	83 c3 01             	add    $0x1,%ebx
801063dc:	81 fb ff 03 00 00    	cmp    $0x3ff,%ebx
801063e2:	77 09                	ja     801063ed <freevm+0x61>
    if(pgdir[i] & PTE_P){
801063e4:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
801063e7:	a8 01                	test   $0x1,%al
801063e9:	74 ee                	je     801063d9 <freevm+0x4d>
801063eb:	eb d6                	jmp    801063c3 <freevm+0x37>
    }
  }
  kfree((char*)pgdir);
801063ed:	83 ec 0c             	sub    $0xc,%esp
801063f0:	56                   	push   %esi
801063f1:	e8 72 bc ff ff       	call   80102068 <kfree>
}
801063f6:	83 c4 10             	add    $0x10,%esp
801063f9:	8d 65 f8             	lea    -0x8(%ebp),%esp
801063fc:	5b                   	pop    %ebx
801063fd:	5e                   	pop    %esi
801063fe:	5d                   	pop    %ebp
801063ff:	c3                   	ret    

80106400 <setupkvm>:
{
80106400:	f3 0f 1e fb          	endbr32 
80106404:	55                   	push   %ebp
80106405:	89 e5                	mov    %esp,%ebp
80106407:	56                   	push   %esi
80106408:	53                   	push   %ebx
  if((pgdir = (pde_t*)kalloc()) == 0)
80106409:	e8 81 bd ff ff       	call   8010218f <kalloc>
8010640e:	89 c6                	mov    %eax,%esi
80106410:	85 c0                	test   %eax,%eax
80106412:	74 55                	je     80106469 <setupkvm+0x69>
  memset(pgdir, 0, PGSIZE);
80106414:	83 ec 04             	sub    $0x4,%esp
80106417:	68 00 10 00 00       	push   $0x1000
8010641c:	6a 00                	push   $0x0
8010641e:	50                   	push   %eax
8010641f:	e8 fd d9 ff ff       	call   80103e21 <memset>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80106424:	83 c4 10             	add    $0x10,%esp
80106427:	bb 20 a4 10 80       	mov    $0x8010a420,%ebx
8010642c:	81 fb 60 a4 10 80    	cmp    $0x8010a460,%ebx
80106432:	73 35                	jae    80106469 <setupkvm+0x69>
                (uint)k->phys_start, k->perm) < 0) {
80106434:	8b 43 04             	mov    0x4(%ebx),%eax
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start,
80106437:	8b 4b 08             	mov    0x8(%ebx),%ecx
8010643a:	29 c1                	sub    %eax,%ecx
8010643c:	83 ec 08             	sub    $0x8,%esp
8010643f:	ff 73 0c             	pushl  0xc(%ebx)
80106442:	50                   	push   %eax
80106443:	8b 13                	mov    (%ebx),%edx
80106445:	89 f0                	mov    %esi,%eax
80106447:	e8 bd f9 ff ff       	call   80105e09 <mappages>
8010644c:	83 c4 10             	add    $0x10,%esp
8010644f:	85 c0                	test   %eax,%eax
80106451:	78 05                	js     80106458 <setupkvm+0x58>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80106453:	83 c3 10             	add    $0x10,%ebx
80106456:	eb d4                	jmp    8010642c <setupkvm+0x2c>
      freevm(pgdir);
80106458:	83 ec 0c             	sub    $0xc,%esp
8010645b:	56                   	push   %esi
8010645c:	e8 2b ff ff ff       	call   8010638c <freevm>
      return 0;
80106461:	83 c4 10             	add    $0x10,%esp
80106464:	be 00 00 00 00       	mov    $0x0,%esi
}
80106469:	89 f0                	mov    %esi,%eax
8010646b:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010646e:	5b                   	pop    %ebx
8010646f:	5e                   	pop    %esi
80106470:	5d                   	pop    %ebp
80106471:	c3                   	ret    

80106472 <kvmalloc>:
{
80106472:	f3 0f 1e fb          	endbr32 
80106476:	55                   	push   %ebp
80106477:	89 e5                	mov    %esp,%ebp
80106479:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
8010647c:	e8 7f ff ff ff       	call   80106400 <setupkvm>
80106481:	a3 84 55 11 80       	mov    %eax,0x80115584
  switchkvm();
80106486:	e8 44 fb ff ff       	call   80105fcf <switchkvm>
}
8010648b:	c9                   	leave  
8010648c:	c3                   	ret    

8010648d <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
8010648d:	f3 0f 1e fb          	endbr32 
80106491:	55                   	push   %ebp
80106492:	89 e5                	mov    %esp,%ebp
80106494:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80106497:	b9 00 00 00 00       	mov    $0x0,%ecx
8010649c:	8b 55 0c             	mov    0xc(%ebp),%edx
8010649f:	8b 45 08             	mov    0x8(%ebp),%eax
801064a2:	e8 f1 f8 ff ff       	call   80105d98 <walkpgdir>
  if(pte == 0)
801064a7:	85 c0                	test   %eax,%eax
801064a9:	74 05                	je     801064b0 <clearpteu+0x23>
    panic("clearpteu");
  *pte &= ~PTE_U;
801064ab:	83 20 fb             	andl   $0xfffffffb,(%eax)
}
801064ae:	c9                   	leave  
801064af:	c3                   	ret    
    panic("clearpteu");
801064b0:	83 ec 0c             	sub    $0xc,%esp
801064b3:	68 0e 70 10 80       	push   $0x8010700e
801064b8:	e8 9f 9e ff ff       	call   8010035c <panic>

801064bd <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
801064bd:	f3 0f 1e fb          	endbr32 
801064c1:	55                   	push   %ebp
801064c2:	89 e5                	mov    %esp,%ebp
801064c4:	57                   	push   %edi
801064c5:	56                   	push   %esi
801064c6:	53                   	push   %ebx
801064c7:	83 ec 1c             	sub    $0x1c,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
801064ca:	e8 31 ff ff ff       	call   80106400 <setupkvm>
801064cf:	89 45 dc             	mov    %eax,-0x24(%ebp)
801064d2:	85 c0                	test   %eax,%eax
801064d4:	0f 84 b8 00 00 00    	je     80106592 <copyuvm+0xd5>
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
801064da:	bf 00 00 00 00       	mov    $0x0,%edi
801064df:	3b 7d 0c             	cmp    0xc(%ebp),%edi
801064e2:	0f 83 aa 00 00 00    	jae    80106592 <copyuvm+0xd5>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
801064e8:	89 7d e4             	mov    %edi,-0x1c(%ebp)
801064eb:	b9 00 00 00 00       	mov    $0x0,%ecx
801064f0:	89 fa                	mov    %edi,%edx
801064f2:	8b 45 08             	mov    0x8(%ebp),%eax
801064f5:	e8 9e f8 ff ff       	call   80105d98 <walkpgdir>
801064fa:	85 c0                	test   %eax,%eax
801064fc:	74 65                	je     80106563 <copyuvm+0xa6>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
801064fe:	8b 00                	mov    (%eax),%eax
80106500:	a8 01                	test   $0x1,%al
80106502:	74 6c                	je     80106570 <copyuvm+0xb3>
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
80106504:	89 c6                	mov    %eax,%esi
80106506:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    flags = PTE_FLAGS(*pte);
8010650c:	25 ff 0f 00 00       	and    $0xfff,%eax
80106511:	89 45 e0             	mov    %eax,-0x20(%ebp)
    if((mem = kalloc()) == 0)
80106514:	e8 76 bc ff ff       	call   8010218f <kalloc>
80106519:	89 c3                	mov    %eax,%ebx
8010651b:	85 c0                	test   %eax,%eax
8010651d:	74 5e                	je     8010657d <copyuvm+0xc0>
      goto bad;
    memmove(mem, (char*)P2V(pa), PGSIZE);
8010651f:	81 c6 00 00 00 80    	add    $0x80000000,%esi
80106525:	83 ec 04             	sub    $0x4,%esp
80106528:	68 00 10 00 00       	push   $0x1000
8010652d:	56                   	push   %esi
8010652e:	50                   	push   %eax
8010652f:	e8 6d d9 ff ff       	call   80103ea1 <memmove>
    if(mappages(d, (void*)i, PGSIZE, V2P(mem), flags) < 0)
80106534:	83 c4 08             	add    $0x8,%esp
80106537:	ff 75 e0             	pushl  -0x20(%ebp)
8010653a:	81 c3 00 00 00 80    	add    $0x80000000,%ebx
80106540:	53                   	push   %ebx
80106541:	b9 00 10 00 00       	mov    $0x1000,%ecx
80106546:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80106549:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010654c:	e8 b8 f8 ff ff       	call   80105e09 <mappages>
80106551:	83 c4 10             	add    $0x10,%esp
80106554:	85 c0                	test   %eax,%eax
80106556:	78 25                	js     8010657d <copyuvm+0xc0>
  for(i = 0; i < sz; i += PGSIZE){
80106558:	81 c7 00 10 00 00    	add    $0x1000,%edi
8010655e:	e9 7c ff ff ff       	jmp    801064df <copyuvm+0x22>
      panic("copyuvm: pte should exist");
80106563:	83 ec 0c             	sub    $0xc,%esp
80106566:	68 18 70 10 80       	push   $0x80107018
8010656b:	e8 ec 9d ff ff       	call   8010035c <panic>
      panic("copyuvm: page not present");
80106570:	83 ec 0c             	sub    $0xc,%esp
80106573:	68 32 70 10 80       	push   $0x80107032
80106578:	e8 df 9d ff ff       	call   8010035c <panic>
      goto bad;
  }
  return d;

bad:
  freevm(d);
8010657d:	83 ec 0c             	sub    $0xc,%esp
80106580:	ff 75 dc             	pushl  -0x24(%ebp)
80106583:	e8 04 fe ff ff       	call   8010638c <freevm>
  return 0;
80106588:	83 c4 10             	add    $0x10,%esp
8010658b:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
}
80106592:	8b 45 dc             	mov    -0x24(%ebp),%eax
80106595:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106598:	5b                   	pop    %ebx
80106599:	5e                   	pop    %esi
8010659a:	5f                   	pop    %edi
8010659b:	5d                   	pop    %ebp
8010659c:	c3                   	ret    

8010659d <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
8010659d:	f3 0f 1e fb          	endbr32 
801065a1:	55                   	push   %ebp
801065a2:	89 e5                	mov    %esp,%ebp
801065a4:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801065a7:	b9 00 00 00 00       	mov    $0x0,%ecx
801065ac:	8b 55 0c             	mov    0xc(%ebp),%edx
801065af:	8b 45 08             	mov    0x8(%ebp),%eax
801065b2:	e8 e1 f7 ff ff       	call   80105d98 <walkpgdir>
  if((*pte & PTE_P) == 0)
801065b7:	8b 00                	mov    (%eax),%eax
801065b9:	a8 01                	test   $0x1,%al
801065bb:	74 10                	je     801065cd <uva2ka+0x30>
    return 0;
  if((*pte & PTE_U) == 0)
801065bd:	a8 04                	test   $0x4,%al
801065bf:	74 13                	je     801065d4 <uva2ka+0x37>
    return 0;
  return (char*)P2V(PTE_ADDR(*pte));
801065c1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801065c6:	05 00 00 00 80       	add    $0x80000000,%eax
}
801065cb:	c9                   	leave  
801065cc:	c3                   	ret    
    return 0;
801065cd:	b8 00 00 00 00       	mov    $0x0,%eax
801065d2:	eb f7                	jmp    801065cb <uva2ka+0x2e>
    return 0;
801065d4:	b8 00 00 00 00       	mov    $0x0,%eax
801065d9:	eb f0                	jmp    801065cb <uva2ka+0x2e>

801065db <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
801065db:	f3 0f 1e fb          	endbr32 
801065df:	55                   	push   %ebp
801065e0:	89 e5                	mov    %esp,%ebp
801065e2:	57                   	push   %edi
801065e3:	56                   	push   %esi
801065e4:	53                   	push   %ebx
801065e5:	83 ec 0c             	sub    $0xc,%esp
801065e8:	8b 7d 14             	mov    0x14(%ebp),%edi
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
801065eb:	eb 25                	jmp    80106612 <copyout+0x37>
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (va - va0);
    if(n > len)
      n = len;
    memmove(pa0 + (va - va0), buf, n);
801065ed:	8b 55 0c             	mov    0xc(%ebp),%edx
801065f0:	29 f2                	sub    %esi,%edx
801065f2:	01 d0                	add    %edx,%eax
801065f4:	83 ec 04             	sub    $0x4,%esp
801065f7:	53                   	push   %ebx
801065f8:	ff 75 10             	pushl  0x10(%ebp)
801065fb:	50                   	push   %eax
801065fc:	e8 a0 d8 ff ff       	call   80103ea1 <memmove>
    len -= n;
80106601:	29 df                	sub    %ebx,%edi
    buf += n;
80106603:	01 5d 10             	add    %ebx,0x10(%ebp)
    va = va0 + PGSIZE;
80106606:	8d 86 00 10 00 00    	lea    0x1000(%esi),%eax
8010660c:	89 45 0c             	mov    %eax,0xc(%ebp)
8010660f:	83 c4 10             	add    $0x10,%esp
  while(len > 0){
80106612:	85 ff                	test   %edi,%edi
80106614:	74 2f                	je     80106645 <copyout+0x6a>
    va0 = (uint)PGROUNDDOWN(va);
80106616:	8b 75 0c             	mov    0xc(%ebp),%esi
80106619:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    pa0 = uva2ka(pgdir, (char*)va0);
8010661f:	83 ec 08             	sub    $0x8,%esp
80106622:	56                   	push   %esi
80106623:	ff 75 08             	pushl  0x8(%ebp)
80106626:	e8 72 ff ff ff       	call   8010659d <uva2ka>
    if(pa0 == 0)
8010662b:	83 c4 10             	add    $0x10,%esp
8010662e:	85 c0                	test   %eax,%eax
80106630:	74 20                	je     80106652 <copyout+0x77>
    n = PGSIZE - (va - va0);
80106632:	89 f3                	mov    %esi,%ebx
80106634:	2b 5d 0c             	sub    0xc(%ebp),%ebx
80106637:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    if(n > len)
8010663d:	39 df                	cmp    %ebx,%edi
8010663f:	73 ac                	jae    801065ed <copyout+0x12>
      n = len;
80106641:	89 fb                	mov    %edi,%ebx
80106643:	eb a8                	jmp    801065ed <copyout+0x12>
  }
  return 0;
80106645:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010664a:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010664d:	5b                   	pop    %ebx
8010664e:	5e                   	pop    %esi
8010664f:	5f                   	pop    %edi
80106650:	5d                   	pop    %ebp
80106651:	c3                   	ret    
      return -1;
80106652:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106657:	eb f1                	jmp    8010664a <copyout+0x6f>
