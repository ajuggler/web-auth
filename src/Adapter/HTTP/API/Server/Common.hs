{-# LANGUAGE ScopedTypeVariables #-}

module Adapter.HTTP.API.Server.Common where

import ClassyPrelude
import Data.Aeson
import Network.HTTP.Types.Status
import qualified Text.Digestive.Form as DF
import Web.Scotty.Trans

import Adapter.HTTP.API.Server.Utils (digestJSON, jsonErrors)
import Adapter.HTTP.Common
import qualified Domain.Auth as D

-- * Forms

parseAndValidateJSON :: (MonadIO m, MonadUnliftIO m, ToJSON v)
                     => DF.Form v m a -> ActionT m a
parseAndValidateJSON form = do
  val <- jsonData `catch` (\(_ :: SomeException) -> return Null)
  validationResult <- lift $ digestJSON form val
  case validationResult of
    (v, Nothing) -> do
      status status400
      json $ jsonErrors v
      finish
    (_, Just result) ->
      return result

-- * Sessions

reqCurrentUserId :: (MonadIO m, D.SessionRepo m) => ActionT m D.UserId
reqCurrentUserId = do
  mayUserId <- getCurrentUserId
  case mayUserId of
    Nothing -> do
      status status401
      json ("AuthRequired" :: Text)
      finish
    Just userId ->
      return userId

-- * Error response

errorResponse :: (ToJSON a) => a -> Value
errorResponse val = object [ "error" .= val ]
