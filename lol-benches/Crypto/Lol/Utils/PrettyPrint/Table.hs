{-|
Module      : Crypto.Lol.Utils.PrettyPrint.Table
Description : Pretty-printing for benchmark results within a single level of the Lol stack.
Copyright   : (c) Eric Crockett, 2011-2017
                  Chris Peikert, 2011-2017
License     : GPL-2
Maintainer  : ecrockett0@email.com
Stability   : experimental
Portability : POSIX

Pretty-printing for benchmark results within a single level of the Lol stack.
-}

{-# LANGUAGE BangPatterns    #-}
{-# LANGUAGE RecordWildCards #-}

module Crypto.Lol.Utils.PrettyPrint.Table
(prettyBenches
,defaultOpts
,Opts(..)
,Verb(..)) where

import Control.Monad (forM_, when)

import Criterion.Types

import Criterion.Measurement (secs)

import Crypto.Lol.Utils.PrettyPrint

import Data.List (nub, groupBy, transpose)

import System.IO
import Text.Printf


data Opts = Opts
  {verb          :: Verb,     -- ^ Verbosity
   level         :: String,   -- ^ Which level of Lol to benchmark
   benches       :: [String], -- ^ Which operations to benchmark. The empty list means run all benchmarks.
   params        :: [String], -- ^ Which parameters to benchmark. The empty list means run all parameters.
   colWidth      :: Int,      -- ^ Character width of data columns
   testNameWidth :: Int}      -- ^ Character width of row labels

optsToInternal :: Opts -> Benchmark -> OptsInternal
optsToInternal Opts{..} bnch =
  OptsInternal{params=if null params
                      then nub $ map getBenchParams $ benchNames bnch
                      else params,
               levels=if null level
                      then nub $ map getBenchLvl $ benchNames bnch
                      else [level],
               benches=if null benches
                       then nub $ map getBenchFunc $ benchNames bnch
                       else benches,
               redThreshold = 0,
               ..}

-- | Runs all benchmarks with verbosity 'Progress'.
defaultOpts :: Maybe String -> Opts
defaultOpts lvl =
  case lvl of
    Nothing -> go ""
    (Just l) -> go l
  where go level =
          Opts {verb = Progress,
                benches = [],
                params = [],
                colWidth = 30,
                testNameWidth=20, ..}

-- | Takes benchmark options an a benchmark group nested as params/level/op,
-- and prints a table comparing operations across all selected levels of Lol.
prettyBenches :: Opts -> Benchmark-> IO ()
prettyBenches o bnch = do
  hSetBuffering stdout NoBuffering -- for better printing of progress
  let o'@OptsInternal{..} = optsToInternal o bnch
  rpts <- getReports o' bnch
  when (verb == Progress) $ putStrLn ""
  printTable o' $ reverse rpts

printTable :: OptsInternal -> [Report] -> IO ()
printTable _ [] = return ()
printTable o rpts = do
  let colLbls = nub $ map (getBenchParams . reportName) rpts
      exName = reportName $ head rpts
  printf (testName o) $ (getTableName exName) ++ "/" ++ (getBenchLvl exName)
  mapM_ (printf (col o)) colLbls
  printf "\n"
  let rpts' = transpose $ groupBy (\a b -> getBenchParams (reportName a) == getBenchParams (reportName b)) rpts
  mapM_ (printRow o) rpts'
  putStrLn ""

-- See Criterion.Internal.analyseOne
printRow :: OptsInternal -> [Report] -> IO ()
printRow o@OptsInternal{..} xs@(rpt : _) = do
  printf (testName o) $ getBenchFunc $ reportName rpt
  let times = map (secs . getRuntime) xs
  forM_ times (printf (col o))
  putStrLn ""
