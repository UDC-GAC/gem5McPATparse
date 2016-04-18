#ifndef ISA
# define ISA

/* Default to X86. */
# if !defined(ISA_X86) && !defined(ISA_ARM) && !defined(ISA_GENERIC)
#  define ISA_X86
# endif

/* Define the possible dataset sizes. */
#  ifdef ISA_X86
#   define INT_EXE 2
#   define FP_EXE  8
#  endif

#  ifdef ISA_ARM
#   define INT_EXE 3
#   define FP_EXE  7
#  endif

#  ifdef ISA_GENERIC 
#   define INT_EXE 3
#   define FP_EXE  6
#  endif

#endif /* !ISA */
