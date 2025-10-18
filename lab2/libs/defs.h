/* 宏定义 */
#ifndef __LIBS_DEFS_H__
#define __LIBS_DEFS_H__

#ifndef NULL
#define NULL ((void *)0)  //将 NULL 定义为空指针常量 ((void *)0)
#endif

#define __always_inline inline __attribute__((always_inline))  //__always_inline 宏，把函数声明替换为 inline 并附加 GCC 的 always_inline 属性，提示编译器务必内联。
#define __noinline __attribute__((noinline)) //__noinline 宏，使用 noinline 属性阻止编译器内联函数。
#define __noreturn __attribute__((noreturn)) //__noreturn 宏，使用 noreturn 属性声明函数不会返回

/* 类型说明 */
typedef int bool;  //将 bool 定义为 int

/* 定义具有明确位宽的整数类型 */
typedef char int8_t;
typedef unsigned char uint8_t;
typedef short int16_t;
typedef unsigned short uint16_t;
typedef int int32_t;
typedef unsigned int uint32_t;
typedef long long int64_t;
typedef unsigned long long uint64_t;

/* 定义“fast”系列类型（根据平台选择更快的整型） */
typedef signed char int_fast8_t; //选用 signed char 表示最快的 8 位有符号整型
typedef short int_fast16_t; //选用 short 作为快速的 16 位有符号整型
typedef long int_fast32_t; //选用 long 作为快速的 32 位有符号整型
typedef long long int_fast64_t; //选用 long long 作为快速的 64 位有符号整型

typedef unsigned char uint_fast8_t; //选用 unsigned char 作为快速的 8 位无符号整型
typedef unsigned short uint_fast16_t;
typedef unsigned long uint_fast32_t;
typedef unsigned long long uint_fast64_t;

/* *
 * 系统中指针和地址长度为 64 位。
 * 使用指针类型来表示地址值
 * 强调 uintptr_t 用来保存地址的数值形式
 * */
typedef int64_t intptr_t; //将 intptr_t 定义为 int64_t，表示可存储指针的有符号整数
typedef uint64_t uintptr_t; //将 uintptr_t 定义为 uint64_t，表示可存储指针的无符号整数

/* size_t 的用途是描述内存尺寸 */
typedef uintptr_t size_t; //将 size_t 定义成 uintptr_t，确保尺寸类型与地址宽度一致

/* 接下来定义页号类型 */
typedef size_t ppn_t; //将 ppn_t（physical page number）定义为 size_t，方便表达页编号

/* *
 * 取整宏在 n 为 2 的幂时效率更高
 * ROUNDDOWN 的行为是向下取整到 n 的倍数
 * */
#define ROUNDDOWN(a, n) ({                                          \
            size_t __a = (size_t)(a);                               \
            (typeof(a))(__a - __a % (n));                           \
        })

/* ROUNDUP 宏的行为是向上取整到 n 的倍数 */
#define ROUNDUP(a, n) ({                                            \
            size_t __n = (size_t)(n);                               \
            (typeof(a))(ROUNDDOWN((size_t)(a) + __n - 1, __n));     \
        })

/* 定义结构成员的偏移量宏 */
#define offsetof(type, member)                                      \
    ((size_t)(&((type *)0)->member))  //将空指针转成目标类型并取成员地址，再转成 size_t 即得偏移。

/* *
 * to_struct - 通过成员指针还原外层结构体指针
 * @ptr:    成员的指针
 * @type:   外层结构体类型
 * @member: 结构体中的成员名
 * */
 //通过偏移量从成员指针回退到结构体首地址
#define to_struct(ptr, type, member)                               \
    ((type *)((char *)(ptr) - offsetof(type, member)))

#endif /* !__LIBS_DEFS_H__ */

