{-# LANGUAGE OverloadedStrings #-}

module Args
  ( Args (..),
    parseArgs,
  )
where

import Data.Maybe
import Data.Semigroup ((<>))
import Data.Text
import Options.Applicative

data Args = Args
  { nixDir :: Text,
    install :: Bool,
    excludeDirs :: [Text]
  }
  deriving (Show, Eq)

parseArgsBase :: Parser Args
parseArgsBase =
  Args
    <$> strOption
      ( short 'd'
          <> long "dir"
          <> help "local nix directory"
      )
    <*> switch
      ( short 'i'
          <> long "install"
          <> help "use to install nix"
      )
    <*> ( fromMaybe []
            <$> optional
              ( splitOn ","
                  <$> strOption
                    ( short 'e'
                        <> long "exclude"
                        <> help "dirs to exclude in root"
                    )
              )
        )

parseArgsInfo :: ParserInfo Args
parseArgsInfo =
  info
    (parseArgsBase <**> helper)
    ( fullDesc
        <> progDesc "Use nix with non-standard nix-store"
        <> header "nix-user-chroot - use nix with non-standard nix-store"
    )

parseArgs :: IO Args
parseArgs = execParser parseArgsInfo
