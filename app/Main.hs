{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# OPTIONS_GHC -Wno-name-shadowing #-}

module Main where

import Control.Lens hiding ((.=))
import Data.Aeson.Lens
import qualified Data.ByteString.Char8 as C8
import Data.Text (Text)
import Data.Yaml
import Data.Yaml.TH

type Step = Value

checkoutAction :: Step
checkoutAction =
  [yamlQQ|
    uses: actions/checkout@v3
  |]

sshAgent :: Step
sshAgent =
  [yamlQQ|
    uses: webfactory/ssh-agent@v0.4.1
    with:
      ssh-private-key: foo
  |]

setupElixir :: Step
setupElixir =
  [yamlQQ|
    uses: erlef/setup-elixir@v1
    with:
      otp-version: ${{ matrix.otp-version }}
      elixir-version: ${{ matrix.elixir-version }}
  |]

downloadElixirDeps :: Step
downloadElixirDeps =
  [yamlQQ|
    name: Download Elixir dependencies
    run: |
      mix local.hex --force
      mix local.rebar --force
      mix deps.get
  |]

buildElixirDeps :: Step
buildElixirDeps =
  [yamlQQ|
    name: Build the dependencies
    run: mix deps.compile
  |]

steps :: Value
steps =
  array
    [ checkoutAction
    , sshAgent
    , setupElixir & key "with" . key "elixir-version" .~ "1.14.0"
    , downloadElixirDeps
    , buildElixirDeps
    ]

data Agent = Agent
  { version :: Text
  , private_key :: Text
  }

instance ToJSON Agent where
  toJSON agent =
    object
      [ "uses" .= ("webfactory/ssh-agent@" <> agent.version)
      , "with"
          .= object
            ["ssh-private_key" .= agent.private_key]
      ]

foo :: IO ()
foo =
  let agent = Agent{version = "v0.4.2", private_key = "foobarbaz"}
   in C8.putStrLn $ encode agent

main :: IO ()
main = do
  C8.putStrLn $ encode steps
  foo
