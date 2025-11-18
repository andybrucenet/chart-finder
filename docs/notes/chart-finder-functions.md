# chart-finder-functions.md

Identified functions for chart-finder app to guide development

## Driving Factor

Revenue Generation - either ads or purchase or subscription (or all).

If the app simply does one thing, that is enough to ship:
  "Native app (mobile / desktop) that: Given a *playable* URI, analyze and find charts that the musician can view in realtime"

Everything else listed below is provided by larger companies with hundreds of devs and millions of funding. Thus they must be implemented as they make sense and only after "go-live".

## Prioritization

These are the top elements to work on first.

* Revenue - get ad-revenue or fee from users
* User integration (oauth)
* Given an input *playable* URI:
  + Song identification
  + Find available charts

## Overall Function List

List of functions that chart-finder wants to provide.

* General
  + Platform Integration 
    * Mobile
      + Designed for use real-time (not analysis)
      + Song identification via URI
      + Chart searching
      + Access customized charts
    * Desktop
      + macOS / Windows (native apps)
      + Includes all mobile features
      + Also permits chart editing (customization)
  + Store integration
    * Ad-supported if not purchased
    * No storage of payment credentials
  + Login with Google / FaceBook / Apple / Amazon / what else??
    * Minimal profile access / storage
    * Maintain persistent login where possible
  + Skinnable wih dark-mode support
* Capabilities
  + Identify new songs
    * Provider integration
      + YouTube / Apple Music / Amazon Music / Spotify
    * Integrate temporary access via provider login
    * Video link access
      + Access videos by URI
      + *Possibly* some level of external search
      + Run from server (to access video analysis tools)
      + Pass temporary provider login credentials to backend
  + Song analysis
    * Multi-pronged approach (run in parallel)
      + Run from server (to access video analysis tools)
    * Song recognition services
      + Shazam / SoundHound
      + AI integration
      + Other?
    * Pattern recognition
      + Most songs have intro / ( verse / chorus.. ) bridge ( chorus / verse ) outro
    * Song metadata
      + BPM
      + Key
      + Tuning (e.g. A=432, A=415, etc.)
  + Chart integration
    * Identify desired chart type (Staff, Chords, Tablature)
    * Search for extant charts
      + Via services (e.g. Soundcharts, iReal Pro, Guitar Tabs)
      + Static charts (e.g. Musicnotes.com, Avid Sibelius, Steinburg Dorico, MuseScore)
      + Categorization (Praise, Pop, HipHop, Rap, Rock, Classical)
    * Chart creation
      + Any services for this (unknown)
      + Target instrument type (e.g. Bb vs Eb vs C instruments)
      + Identify "stems" (individual voices)
  + Chart Library
    * Access saved charts where licensing permits (e.g. DRM; paid scores from MuseScore may not permit editing / duplication / storage)
    * Chart editing
      + Desktop only
      + Key change, tablature change (e.g. tabs to chords to staff)
    * Permit setlist creation / editing
    * Integration with popular remote tools like AirDuo for page turn / etc.

