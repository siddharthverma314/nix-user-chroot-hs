module Chroot (chroot) where

import Foreign.C
import System.Directory (setCurrentDirectory)

foreign import ccall "unistd.h chroot" chrootC :: CString -> IO Int

chroot :: String -> IO ()
chroot dir = do throwErrnoIfMinus1_ "chroot" (withCString dir chrootC)
                setCurrentDirectory "/"
