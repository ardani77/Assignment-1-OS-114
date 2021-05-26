# Code Modification Report

## Makefile
Line 3 :
```C
CS333_PROJECT ?= 2
```

## user.h
Line 28 - 30:
```C
#ifdef CS333_P1
int date(struct rtcdate*);
#endif // CS333_P1
```

## usys.s
Line 33:
```
SYSCALL(date)
```

## syscall.h
Line 24:
```C
#define SYS_date    SYS_halt+1
```

## syscall.c
Line 109 - 112:
```C
#ifdef CS333_P1
// internally, the function prototype must be ’int’ not ’uint’ for sys_date()
extern int sys_date(void);
#endif // CS333_P1
```
Line 139 - 141:
```C
#ifdef CS333_P1
[SYS_date]    sys_date,
#endif // CS333_P1
```
Line 182 - 185:
```C
#ifdef CS333_P1
    #ifdef PRINT_SYSCALLS
        cprintf("%s -> %d\n",
                syscallnames[num], curproc->tf->eax);
    #endif
#endif
```

## sysproc.c
Line 101 - 111:
```C
#ifdef CS333_P1
int
sys_date(void)
{
  struct rtcdate *d;
  if(argptr(0, (void*)&d, sizeof(struct rtcdate)) < 0)
    return -1;
  cmostime(d);
  return 0;
}
#endif // CS333_P1
```

## proc.h
Line 52 - 54:
```C
#ifdef CS333_P1
  uint start_ticks;
#endif // CS333_P1
```

## proc.c
Line 152 - 154:
```C
#ifdef CS333_P1
  p->start_ticks = ticks;
#endif // CS333_P1
```
Line 570 - 574:
```C
#ifdef CS333_P1
    uint elapsed_in_ms = ticks - p->start_ticks;
    uint elapsed_in_sec = elapsed_in_ms / 1000;
    uint elapsed_decimal = elapsed_in_ms % 1000;

    cprintf("%d\t%s\t\t%d.%d\t%s\t%d\t", p->pid, p->name, elapsed_in_sec, elapsed_decimal, state_string, p->sz);
  #endif // CS333_P1
```