Started Minty-GI! ===

thread '<unnamed>' panicked at src\lib.rs:24:29:
called `Result::unwrap()` on an `Err` value: Error { code: HRESULT(0x80070005), message: "Access is denied." }
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace

thread '<unnamed>' panicked at library\core\src\panicking.rs:225:5:
panic in a function that cannot unwind
stack backtrace:
   0:     0x7ffaeab7fcac - DllMain
   1:     0x7ffaeab4b72b - DllMain
   2:     0x7ffaeab7dfc4 - DllMain
   3:     0x7ffaeab7fad4 - DllMain
   4:     0x7ffaeab7da63 - DllMain
   5:     0x7ffaeab87cf3 - DllMain
   6:     0x7ffaeab87c7f - DllMain
   7:     0x7ffaeab885ae - DllMain
   8:     0x7ffaeab8bddb - DllMain
   9:     0x7ffaeab8be55 - DllMain
  10:     0x7ffaeab8be03 - DllMain
  11:     0x7ffaeab48c39 - DllMain
  12:     0x7ffb67460430 - _CxxFrameHandler3
  13:     0x7ffb6745342d - is_exception_typeof
  14:     0x7ffb84bd1d46 - RtlCaptureContext2
  15:     0x7ffaeab489e2 - DllMain
  16:     0x7ffaeab89342 - DllMain
  17:     0x7ffb84b49a1d - RtlActivateActivationContextUnsafeFast
  18:     0x7ffb84b9d327 - LdrGetProcedureAddressEx
  19:     0x7ffb84b9d0ba - LdrGetProcedureAddressEx
  20:     0x7ffb84b6d947 - RtlSwitchedVVI
  21:     0x7ffb84b4fbae - RtlGetFullPathName_UstrEx
  22:     0x7ffb84b473e4 - RtlDosPathNameToNtPathName_U
  23:     0x7ffb84b46af4 - LdrLoadDll
  24:     0x7ffb8281db72 - LoadLibraryExW
  25:     0x7ff7bcbbabcc - Ordinal0
  26:     0x7ff7bcbb915d - Ordinal0
  27:     0x7ff7bc2c474d - Ordinal0
  28:     0x7ff7d1b16d5d - AmdPowerXpressRequestHighPerformance
  29:     0x7ff7bc2bfe2b - Ordinal0
  30:     0x7ff7bd6816aa - Ordinal0
  31:     0x7ffb834a7374 - BaseThreadInitThunk
  32:     0x7ffb84b7cc91 - RtlUserThreadStart
thread caused non-unwinding panic. aborting.
