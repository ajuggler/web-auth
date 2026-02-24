{-# LANGUAGE ScopedTypeVariables #-}

module Adapter.HTTP.Main where

import ClassyPrelude
import Katip
import Network.Wai
import Network.Wai.Middleware.Gzip
import Network.HTTP.Types.Status
import Web.Scotty.Trans

import qualified Adapter.HTTP.API.Auth as AuthAPI
import Adapter.HTTP.Common
import qualified Domain.Auth as D

main :: ( MonadIO m, MonadUnliftIO m, KatipContext m, D.AuthRepo m, D.EmailVerificationNotif m, D.SessionRepo m )
     => Int -> (m Response -> IO Response) -> IO ()
main port runner =
  scottyT port runner routes

routes
  :: ( MonadIO m
     , MonadUnliftIO m
     , KatipContext m
     , D.AuthRepo m
     , D.EmailVerificationNotif m
     , D.SessionRepo m
     )
  => ScottyT m ()
routes = do
  middleware . gzip $ defaultGzipSettings { gzipFiles = GzipCompress }

  AuthAPI.routes

  defaultHandler $
    Handler $ \(e :: SomeException) -> do
      lift $ $(logTM) ErrorS $ "Unhandled error: " <> ls (displayException e)
      status status500
      json ("InternalServiceError" :: Text)
