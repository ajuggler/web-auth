-- | Module providing the scotty backend for the digestive-functors library
-- (Based on https://hackage.haskell.org/package/digestive-functors-scotty)
module Adapter.HTTP.Web.Utils
    ( runForm
    ) where

import           ClassyPrelude
import qualified Data.Text             as T
import qualified Data.ByteString.Char8 as B
import qualified Web.Scotty.Trans      as Scotty
import           Network.Wai           (requestMethod)
import           Network.Wai.Parse     (fileName)
import           Network.HTTP.Types    (methodGet)

import           Text.Digestive.Form
import           Text.Digestive.Types
import           Text.Digestive.View

scottyEnv :: (Monad m, MonadUnliftIO m) => Env (Scotty.ActionT m)
scottyEnv path = do
  inputs <- parse (TextInput . id) Scotty.pathParams
  files  <- parse (FileInput . B.unpack . fileName) Scotty.files
  return $ inputs ++ files
  where
    parse :: Monad m => (b -> FormInput) -> Scotty.ActionT m [(T.Text, b)] -> Scotty.ActionT m [FormInput]
    parse f action = do
      ps <- action
      pure [ f v | (k, v) <- ps, k == name ]

    name :: T.Text
    name = fromPath path

-- | Runs a form with the HTTP input provided by Scotty.
runForm :: (Monad m, MonadUnliftIO m)
        => T.Text                               -- ^ Name of the form
        -> Form v (Scotty.ActionT m) a          -- ^ Form to run
        -> (Scotty.ActionT m) (View v, Maybe a) -- ^ Result
runForm name form = Scotty.request >>= \rq ->
    if requestMethod rq == methodGet
        then getForm name form >>= \v -> return (v, Nothing)
        else postForm name form $ const (return scottyEnv)
