---
layout: default
title:  "Why static_cast void(or (void)0) and LogMessageVoidify are needed in logging macros"
date:   2022-06-14 14:25:33 +0800
categories: [webrtc,logging]
---

# Abstract
Explain that why `static_cast<void>(0)` or `(void) 0` and `LogMessageVoidify` needed in logging helper macros.

# Example
Use an example to explain the question.
## Source code of example
```C++
// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <stddef.h>

#include <cassert>
#include <cstdint>
#include <sstream>
#include <string>

#define BASE_EXPORT __attribute__((visibility("default")))
namespace logging {

typedef char PathChar;

// A bitmask of potential logging destinations.
using LoggingDestination = uint32_t;
// Specifies where logs will be written. Multiple destinations can be specified
// with bitwise OR.
// Unless destination is LOG_NONE, all logs with severity ERROR and above will
// be written to stderr in addition to the specified destination.
enum : uint32_t {
  LOG_NONE                = 0,
  LOG_TO_FILE             = 1 << 0,
  LOG_TO_SYSTEM_DEBUG_LOG = 1 << 1,
  LOG_TO_STDERR           = 1 << 2,

  LOG_TO_ALL = LOG_TO_FILE | LOG_TO_SYSTEM_DEBUG_LOG | LOG_TO_STDERR,

  LOG_DEFAULT = LOG_TO_SYSTEM_DEBUG_LOG | LOG_TO_STDERR,
};

// Indicates that the log file should be locked when being written to.
// Unless there is only one single-threaded process that is logging to
// the log file, the file should be locked during writes to make each
// log output atomic. Other writers will block.
//
// All processes writing to the log file must have their locking set for it to
// work properly. Defaults to LOCK_LOG_FILE.
enum LogLockingState { LOCK_LOG_FILE, DONT_LOCK_LOG_FILE };

// On startup, should we delete or append to an existing log file (if any)?
// Defaults to APPEND_TO_OLD_LOG_FILE.
enum OldFileDeletionState { DELETE_OLD_LOG_FILE, APPEND_TO_OLD_LOG_FILE };


struct BASE_EXPORT LoggingSettings {
  // Equivalent to logging destination enum, but allows for multiple
  // destinations.
  uint32_t logging_dest = LOG_DEFAULT;

  // The four settings below have an effect only when LOG_TO_FILE is
  // set in |logging_dest|.
  const PathChar* log_file_path = nullptr;
  LogLockingState lock_log = LOCK_LOG_FILE;
  OldFileDeletionState delete_old = APPEND_TO_OLD_LOG_FILE;
};

// Define different names for the BaseInitLoggingImpl() function depending on
// whether NDEBUG is defined or not so that we'll fail to link if someone tries
// to compile logging.cc with NDEBUG but includes logging.h without defining it,
// or vice versa.
#if defined(NDEBUG)
#define BaseInitLoggingImpl BaseInitLoggingImpl_built_with_NDEBUG
#else
#define BaseInitLoggingImpl BaseInitLoggingImpl_built_without_NDEBUG
#endif

// Implementation of the InitLogging() method declared below.  We use a
// more-specific name so we can #define it above without affecting other code
// that has named stuff "InitLogging".
BASE_EXPORT bool BaseInitLoggingImpl(const LoggingSettings& settings);

// Sets the log file name and other global logging state. Calling this function
// is recommended, and is normally done at the beginning of application init.
// If you don't call it, all the flags will be initialized to their default
// values, and there is a race condition that may leak a critical section
// object if two threads try to do the first log at the same time.
// See the definition of the enums above for descriptions and default values.
//
// The default log file is initialized to "debug.log" in the application
// directory. You probably don't want this, especially since the program
// directory may not be writable on an enduser's system.
//
// This function may be called a second time to re-direct logging (e.g after
// loging in to a user partition), however it should never be called more than
// twice.
inline bool InitLogging(const LoggingSettings& settings) {
  return BaseInitLoggingImpl(settings);
}

// Sets the log level. Anything at or above this level will be written to the
// log file/displayed to the user (if applicable). Anything below this level
// will be silently ignored. The log level defaults to 0 (everything is logged
// up to level INFO) if this function is not called.
// Note that log messages for VLOG(x) are logged at level -x, so setting
// the min log level to negative values enables verbose logging.
BASE_EXPORT void SetMinLogLevel(int level);

// Gets the current log level.
BASE_EXPORT int GetMinLogLevel();

// Used by LOG_IS_ON to lazy-evaluate stream arguments.
BASE_EXPORT bool ShouldCreateLogMessage(int severity){return true;}

// Gets the VLOG default verbosity level.
BASE_EXPORT int GetVlogVerbosity();

// Note that |N| is the size *with* the null terminator.
BASE_EXPORT int GetVlogLevelHelper(const char* file_start, size_t N);

// Gets the current vlog level for the given file (usually taken from __FILE__).
template <size_t N>
int GetVlogLevel(const char (&file)[N]) {
  return GetVlogLevelHelper(file, N);
}

// Sets the common items you want to be prepended to each log message.
// process and thread IDs default to off, the timestamp defaults to on.
// If this function is not called, logging defaults to writing the timestamp
// only.
BASE_EXPORT void SetLogItems(bool enable_process_id, bool enable_thread_id,
                             bool enable_timestamp, bool enable_tickcount);

// Sets an optional prefix to add to each log message. |prefix| is not copied
// and should be a raw string constant. |prefix| must only contain ASCII letters
// to avoid confusion with PIDs and timestamps. Pass null to remove the prefix.
// Logging defaults to no prefix.
BASE_EXPORT void SetLogPrefix(const char* prefix);

// Sets whether or not you'd like to see fatal debug messages popped up in
// a dialog box or not.
// Dialogs are not shown by default.
BASE_EXPORT void SetShowErrorDialogs(bool enable_dialogs);

using LogSeverity = int;
const LogSeverity LOGGING_VERBOSE = -1;  // This is level 1 verbosity
// Note: the log severities are used to index into the array of names,
// see log_severity_names.
const LogSeverity LOGGING_INFO = 0;
const LogSeverity LOGGING_WARNING = 1;
const LogSeverity LOGGING_ERROR = 2;
const LogSeverity LOGGING_FATAL = 3;
const LogSeverity LOGGING_NUM_SEVERITIES = 4;

// LOGGING_DFATAL is LOGGING_FATAL in DCHECK-enabled builds, ERROR in normal
// mode.
const LogSeverity LOGGING_DFATAL = LOGGING_ERROR;

// This block duplicates the above entries to facilitate incremental conversion
// from LOG_FOO to LOGGING_FOO.
// TODO(thestig): Convert existing users to LOGGING_FOO and remove this block.
const LogSeverity LOG_VERBOSE = LOGGING_VERBOSE;
const LogSeverity LOG_INFO = LOGGING_INFO;
const LogSeverity LOG_WARNING = LOGGING_WARNING;
const LogSeverity LOG_ERROR = LOGGING_ERROR;
const LogSeverity LOG_FATAL = LOGGING_FATAL;
const LogSeverity LOG_DFATAL = LOGGING_DFATAL;

// A few definitions of macros that don't generate much code. These are used
// by LOG() and LOG_IF, etc. Since these are used all over our code, it's
// better to have compact code for these operations.
#define COMPACT_GOOGLE_LOG_EX_INFO(ClassName, ...)                  \
  ::logging::ClassName(__FILE__, __LINE__, ::logging::LOGGING_INFO, \
                       ##__VA_ARGS__)
#define COMPACT_GOOGLE_LOG_EX_WARNING(ClassName, ...)                  \
  ::logging::ClassName(__FILE__, __LINE__, ::logging::LOGGING_WARNING, \
                       ##__VA_ARGS__)
#define COMPACT_GOOGLE_LOG_EX_ERROR(ClassName, ...)                  \
  ::logging::ClassName(__FILE__, __LINE__, ::logging::LOGGING_ERROR, \
                       ##__VA_ARGS__)
#define COMPACT_GOOGLE_LOG_EX_FATAL(ClassName, ...)                  \
  ::logging::ClassName(__FILE__, __LINE__, ::logging::LOGGING_FATAL, \
                       ##__VA_ARGS__)
#define COMPACT_GOOGLE_LOG_EX_DFATAL(ClassName, ...)                  \
  ::logging::ClassName(__FILE__, __LINE__, ::logging::LOGGING_DFATAL, \
                       ##__VA_ARGS__)
#define COMPACT_GOOGLE_LOG_EX_DCHECK(ClassName, ...)                  \
  ::logging::ClassName(__FILE__, __LINE__, ::logging::LOGGING_DCHECK, \
                       ##__VA_ARGS__)

#define COMPACT_GOOGLE_LOG_INFO COMPACT_GOOGLE_LOG_EX_INFO(LogMessage)
#define COMPACT_GOOGLE_LOG_WARNING COMPACT_GOOGLE_LOG_EX_WARNING(LogMessage)
#define COMPACT_GOOGLE_LOG_ERROR COMPACT_GOOGLE_LOG_EX_ERROR(LogMessage)
#define COMPACT_GOOGLE_LOG_FATAL COMPACT_GOOGLE_LOG_EX_FATAL(LogMessage)
#define COMPACT_GOOGLE_LOG_DFATAL COMPACT_GOOGLE_LOG_EX_DFATAL(LogMessage)
#define COMPACT_GOOGLE_LOG_DCHECK COMPACT_GOOGLE_LOG_EX_DCHECK(LogMessage)

#if defined(OS_WIN)
// wingdi.h defines ERROR to be 0. When we call LOG(ERROR), it gets
// substituted with 0, and it expands to COMPACT_GOOGLE_LOG_0. To allow us
// to keep using this syntax, we define this macro to do the same thing
// as COMPACT_GOOGLE_LOG_ERROR, and also define ERROR the same way that
// the Windows SDK does for consistency.
#define ERROR 0
#define COMPACT_GOOGLE_LOG_EX_0(ClassName, ...) \
  COMPACT_GOOGLE_LOG_EX_ERROR(ClassName , ##__VA_ARGS__)
#define COMPACT_GOOGLE_LOG_0 COMPACT_GOOGLE_LOG_ERROR
// Needed for LOG_IS_ON(ERROR).
const LogSeverity LOGGING_0 = LOGGING_ERROR;
#endif

// As special cases, we can assume that LOG_IS_ON(FATAL) always holds. Also,
// LOG_IS_ON(DFATAL) always holds in debug mode. In particular, CHECK()s will
// always fire if they fail.
#define LOG_IS_ON(severity) \
  (::logging::ShouldCreateLogMessage(::logging::LOGGING_##severity))

// We don't do any caching tricks with VLOG_IS_ON() like the
// google-glog version since it increases binary size.  This means
// that using the v-logging functions in conjunction with --vmodule
// may be slow.
#define VLOG_IS_ON(verboselevel) \
  ((verboselevel) <= ::logging::GetVlogLevel(__FILE__))

// Helper macro which avoids evaluating the arguments to a stream if
// the condition doesn't hold. Condition is evaluated once and only once.
#define LAZY_STREAM(stream, condition)                                  \
  !(condition) ? (void) 0 : ::logging::LogMessageVoidify() & (stream)

// We use the preprocessor's merging operator, "##", so that, e.g.,
// LOG(INFO) becomes the token COMPACT_GOOGLE_LOG_INFO.  There's some funny
// subtle difference between ostream member streaming functions (e.g.,
// ostream::operator<<(int) and ostream non-member streaming functions
// (e.g., ::operator<<(ostream&, string&): it turns out that it's
// impossible to stream something like a string directly to an unnamed
// ostream. We employ a neat hack by calling the stream() member
// function of LogMessage which seems to avoid the problem.
#define LOG_STREAM(severity) COMPACT_GOOGLE_LOG_ ## severity.stream()

#define LOG(severity) LAZY_STREAM(LOG_STREAM(severity), LOG_IS_ON(severity))
#define LOG_IF(severity, condition) \
  LAZY_STREAM(LOG_STREAM(severity), LOG_IS_ON(severity) && (condition))

// The VLOG macros log with negative verbosities.
#define VLOG_STREAM(verbose_level) \
  ::logging::LogMessage(__FILE__, __LINE__, -(verbose_level)).stream()

#define VLOG(verbose_level) \
  LAZY_STREAM(VLOG_STREAM(verbose_level), VLOG_IS_ON(verbose_level))

#define VLOG_IF(verbose_level, condition) \
  LAZY_STREAM(VLOG_STREAM(verbose_level), \
      VLOG_IS_ON(verbose_level) && (condition))

#define VPLOG_STREAM(verbose_level) \
  ::logging::ErrnoLogMessage(__FILE__, __LINE__, -(verbose_level), \
    ::logging::GetLastSystemErrorCode()).stream()

#define VPLOG(verbose_level) \
  LAZY_STREAM(VPLOG_STREAM(verbose_level), VLOG_IS_ON(verbose_level))

#define VPLOG_IF(verbose_level, condition) \
  LAZY_STREAM(VPLOG_STREAM(verbose_level), \
    VLOG_IS_ON(verbose_level) && (condition))

// TODO(akalin): Add more VLOG variants, e.g. VPLOG.

#define LOG_ASSERT(condition)                       \
  LOG_IF(FATAL, !(ANALYZER_ASSUME_TRUE(condition))) \
      << "Assert failed: " #condition ". "

#define PLOG_STREAM(severity) \
  COMPACT_GOOGLE_LOG_EX_ ## severity(ErrnoLogMessage, \
      ::logging::GetLastSystemErrorCode()).stream()

#define PLOG(severity)                                          \
  LAZY_STREAM(PLOG_STREAM(severity), LOG_IS_ON(severity))

#define PLOG_IF(severity, condition) \
  LAZY_STREAM(PLOG_STREAM(severity), LOG_IS_ON(severity) && (condition))

BASE_EXPORT extern std::ostream* g_swallow_stream;

// Note that g_swallow_stream is used instead of an arbitrary LOG() stream to
// avoid the creation of an object with a non-trivial destructor (LogMessage).
// On MSVC x86 (checked on 2015 Update 3), this causes a few additional
// pointless instructions to be emitted even at full optimization level, even
// though the : arm of the ternary operator is clearly never executed. Using a
// simpler object to be &'d with Voidify() avoids these extra instructions.
// Using a simpler POD object with a templated operator<< also works to avoid
// these instructions. However, this causes warnings on statically defined
// implementations of operator<<(std::ostream, ...) in some .cc files, because
// they become defined-but-unreferenced functions. A reinterpret_cast of 0 to an
// ostream* also is not suitable, because some compilers warn of undefined
// behavior.
#define EAT_STREAM_PARAMETERS \
  true ? (void)0              \
       : ::logging::LogMessageVoidify() & (*::logging::g_swallow_stream)



// Redefine the standard assert to use our nice log files
#undef assert
#define assert(x) DLOG_ASSERT(x)

// This class more or less represents a particular log message.  You
// create an instance of LogMessage and then stream stuff to it.
// When you finish streaming to it, ~LogMessage is called and the
// full message gets streamed to the appropriate destination.
//
// You shouldn't actually use LogMessage's constructor to log things,
// though.  You should use the LOG() macro (and variants thereof)
// above.
class LogMessage {
 public:
  // Used for LOG(severity).
  LogMessage(const char* file, int line, LogSeverity severity): severity_(severity), file_(file), line_(line){}

  // Used for CHECK().  Implied severity = LOGGING_FATAL.
  LogMessage(const char* file, int line, const char* condition): file_(file), line_(line){}
  LogMessage(const LogMessage&) = delete;
  LogMessage& operator=(const LogMessage&) = delete;
  virtual ~LogMessage(){};

  std::ostream& stream() { return stream_; }

  LogSeverity severity() { return severity_; }
  std::string str() { return stream_.str(); }

 private:
  void Init(const char* file, int line);

  LogSeverity severity_;
  std::ostringstream stream_;
  size_t message_start_;  // Offset of the start of the message (past prefix
                          // info).
  // The file and line information passed in to the constructor.
  const char* file_;
  const int line_;
  const char* file_basename_;

};

// This class is used to explicitly ignore values in the conditional
// logging macros.  This avoids compiler warnings like "value computed
// is not used" and "statement has no effect".
class LogMessageVoidify {
 public:
  LogMessageVoidify() = default;
  // This has to be an operator with a precedence lower than << but
  // higher than ?:
  void operator&(std::ostream&) { }
};


}  // namespace logging



int main ()
{
    using namespace logging;
    LOG(INFO)<<"X";
    //true ? (void)0:(int)1;
    return 0;
}
```
## Source code after preprocessor
Preprocessor expands all the macros.
We can use this command to see the final source code after preprocessor.`-E` option is used to do that.
~~~
$  /usr/bin/clang++ -std=c++11 -stdlib=libc++ -g -E /Users/klaus/dev/src/leetcode/webrtc/logging.cpp
~~~
Source code after preprocessor.
```C++
int main ()
{
    using namespace logging;
    !((::logging::ShouldCreateLogMessage(::logging::LOGGING_INFO))) ? (void) 0 : ::logging::LogMessageVoidify() & (::logging::LogMessage("/Users/klaus/dev/src/leetcode/webrtc/logging.cpp", 355, ::logging::LOGGING_INFO).stream())<<"X";
    return 0;
}
```

# Why static_cast<void> or (void)0 needed
- Use static_cast to disacards the value of expression after evaluating it.so that the compiler will not report a compiling warning or error.

More details please see [static_cast in cppreference](https://en.cppreference.com/w/cpp/language/static_cast)
> 4) If new-type is the type void (possibly cv-qualified), static_cast discards the value of expression after evaluating it.

```C++
// 4. discarded-value expression
    static_cast<void>(v2.size());
```

# Why LogMessageVoidify needed
- Sometimes,the logging may not be outputed due to severity restriction.however,value of expression has to be evaluated though.to avoid the compiling warings or errors,we need discarding the value of expression.Therefor `static_cast<void>` is needed.
- We use the `tertiary operator? :` to implement the logging.and the tertiary operator requires that the left value and right value have the same type.
- The type of left value is `void` so that type of right value must be `void` too.

Error encounted if left value and right value has different types.
```shell
Starting build...
/usr/bin/clang++ -std=c++11 -stdlib=libc++ -g /Users/klaus/dev/src/leetcode/webrtc/logging.cpp -o /Users/klaus/dev/src/leetcode/webrtc/logging
/Users/klaus/dev/src/leetcode/webrtc/logging.cpp:356:10: error: left operand to ? is void, but right operand is of type 'int'
    true ? (void)0:(int)1;
         ^ ~~~~~~~ ~~~~~~
1 error generated.

Build finished with error(s).
```

`LogMessageVoidify` overrides operator `&`,and returns `void`,matching the requirements above.
```C++
class LogMessageVoidify {
 public:
  LogMessageVoidify() = default;
  // This has to be an operator with a precedence lower than << but
  // higher than ?:
  void operator&(std::ostream&) { }
};
```

The return type of overrided funcion `<<` of `std::ostream` is `std::ostream`.so if without `LogMessageVoidify`,errors will be triggled compiling the `tertinary operator ?:`
```C++
template <class _CharT, class _Traits>
class _LIBCPP_TEMPLATE_VIS basic_ostream
    : virtual public basic_ios<_CharT, _Traits>
{
......
public:
    basic_ostream& operator<<(basic_ostream& (*__pf)(basic_ostream&))
    { return __pf(*this); }
......
}
```

