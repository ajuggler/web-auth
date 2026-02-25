{-# LANGUAGE ScopedTypeVariables #-}

module Adapter.HTTP.Web.Main where

import ClassyPrelude
import Katip
import Network.HTTP.Types.Status
import Network.Wai
import Network.Wai.Middleware.Gzip
import qualified Network.Wai.Middleware.Static as Static
import Web.Scotty.Trans

import qualified Adapter.HTTP.Web.Auth as Auth
import qualified Domain.Auth as D

main :: ( MonadIO m
        , MonadUnliftIO m
        , KatipContext m
        , D.AuthRepo m
        , D.EmailVerificationNotif m
        , D.SessionRepo m
        )
     => (m Response -> IO Response) -> IO Application
main runner =
  scottyAppT defaultOptions runner routes

routes :: ( MonadIO m
          , MonadUnliftIO m
          , KatipContext m
          , D.AuthRepo m
          , D.EmailVerificationNotif m
          , D.SessionRepo m
          )
       => ScottyT m ()
routes = do
  middleware $
    gzip $ defaultGzipSettings { gzipFiles = GzipCompress }

  middleware $
    Static.staticPolicyWithOptions
      Static.defaultOptions
      (Static.addBase "src/Adapter/HTTP/Web")

  Auth.routes

  notFound $ do
    status status404
    text "Not found"

  defaultHandler $
    Handler $ \(e :: SomeException) -> do
      lift $ $(logTM) ErrorS $ "Unhandled error: " <> ls (displayException e)
      status status500
      text "Internal server error!"
