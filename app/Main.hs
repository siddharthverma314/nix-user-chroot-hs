module Main where

import Args
import Chroot
import Control.Monad (forM_)
import Data.Text (unpack)
import System.Directory
import System.FilePath
import System.Linux.Mount
import System.Linux.Namespaces
import System.Posix hiding (createDirectory, removeDirectory)

child :: Args -> String -> IO ()
child (Args nixDir _ excludeDirs) tmpNixDir = do
  -- unshare
  putStrLn "Unsharing..."
  unshare [PID, User, Mount]

  -- mount all directories to temp dir
  dirs <- filter (`notElem` "nix" : (unpack <$> excludeDirs)) <$> listDirectory "/"
  forM_ dirs $ \dir -> do
    let src = "/" </> dir
        dst = tmpNixDir </> dir
    putStrLn $ "mounting " ++ dir
    createDirectory dst
    rBind src dst

  -- mount nix
  let src = unpack nixDir
      dst = tmpNixDir </> "nix"
  createDirectory dst
  rBind src dst

  -- chroot
  putStrLn "Chroot..."
  chroot tmpNixDir

  print =<< listDirectory "/"

  -- run bash
  putStrLn "Run Bash!"
  executeFile "bash" True [] Nothing

main :: IO ()
main = do
  args <- parseArgs

  tmpNixDir <- ("/tmp" </>) <$> mkdtemp "nix-chroot."
  createDirectory tmpNixDir
  putStrLn $ "Got directory " ++ tmpNixDir

  pid <- forkProcess $ child args tmpNixDir
  _ <- getProcessStatus True False pid

  -- cleanup
  mapM_ (removeDirectory . (tmpNixDir </>)) =<< listDirectory tmpNixDir
  removeDirectory tmpNixDir
