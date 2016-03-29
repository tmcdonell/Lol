
import Challenges.Beacon
import Challenges.Common
import Challenges.Verify

import Control.Applicative ((<$>))
import Control.Monad (when)
import Control.Monad.Except
import Control.Monad.State

import Crypto.Lol (intLog)

import Data.ByteString.Lazy (writeFile)
import Data.Map (Map, lookup, empty, insert)

import Net.Beacon

import Network.HTTP.Conduit (simpleHttp)

import Prelude hiding (lookup, writeFile)

import System.Directory (doesFileExist, removeFile, getDirectoryContents)
import System.IO hiding (writeFile)

main :: IO ()
main = do
  hSetBuffering stdout NoBuffering
  checkChallDirExists

  abspath <- absPath
  let challDir = abspath </> challengeFilesDir
  challs <- filter (("chall" ==) . (take 5)) <$> (getDirectoryContents challDir)
  recs <- flip execStateT empty $ mapM_ (revealChallengeMain abspath) challs
  mapM_ (writeBeaconXML abspath) recs
  
  getNistCert abspath

revealChallengeMain :: FilePath -> String -> StateT (Map Int Record) IO ()
revealChallengeMain abspath name = printPassFail ("Revealing challenge " ++ name ++ ":\n") "DONE" $ do
  let challDir = abspath </> challengeFilesDir </> name
  (BP time offset) <- readRevealData challDir 

  lastRec <- liftIO getLastRecord
  lastBeaconTime <- case lastRec of
    Nothing -> throwError "Failed to get last beacon."
    (Just r) -> return $ timeStamp r

  when ((time `mod` beaconInterval /= 0) || offset < 0 || offset >= bytesPerBeacon) $ 
    throwError "Invalid beacon position."

  when (time > lastBeaconTime) $
    throwError $ "Can't reveal challenge " ++ name ++ 
      ": it's time has not yet come. Please wait " ++ 
      (show $ time-lastBeaconTime) ++ " seconds for the assigned beacon."

  rec <- retrieveRecord time
  let secretIdx = getSecretIdx rec offset
      secDir = abspath </> secretFilesDir </> name
      secFile = secDir </> (secretFileName name secretIdx)

  secFileExists <- liftIO $ doesFileExist secFile
  when (not secFileExists) $ throwError $ secFile ++ " does not exist."

  liftIO $ putStr $ "\tRemoving " ++ secFile ++ "\n\t"
  liftIO $ removeFile secFile

-- attempt to find the record in the state, otherwise read it from NIST
retrieveRecord :: Int -> ExceptT String (StateT (Map Int Record) IO) Record
retrieveRecord t = do
  mrec <- gets (lookup t)
  case mrec of
    (Just r) -> return r
    Nothing -> do
      liftIO $ putStrLn $ "\tDownloading record " ++ (show t)
      r <- liftIO $ getCurrentRecord t
      case r of
        (Just r') -> do
          modify (insert t r')
          return r'
        Nothing -> throwError $ "Couldn't get record " ++ (show t) ++ "from NIST servers."

-- returns last k characters in a string
lastK :: Int -> String -> String
lastK k s =
  let l = length s
  in if l > k
     then drop (l-k) s
     else s

writeBeaconXML :: FilePath -> Record -> IO ()
writeBeaconXML path rec = do
  let beacon = toXML rec
  writeFile (path </> secretFilesDir </> (xmlFileName $ timeStamp rec)) beacon

getNistCert :: FilePath -> IO ()
getNistCert path = do
  let certPath = path </> secretFilesDir </> certFileName
  putStrLn $ "Writing NIST certificate to " ++ certPath
  bs <- simpleHttp "https://beacon.nist.gov/certificate/beacon.cer"
  writeFile certPath bs
  