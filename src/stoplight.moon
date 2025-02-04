require "lib.hsm"

-- Example machine definition: Stoplight
stoplight_def = {
  default: "Red"              -- Initial substate is "Red"

  -- Global timer: every 15s, transition into FlashingRed
  "FlashingRed every 15"

  -- Terminate the HSM after 25s
  "ExitHSM after 25"

  -- keyboard events
  "Green       on G_PRESSED"
  "Red         on R_PRESSED"
  "Yellow      on Y_PRESSED"
  "ExitHSM     on Q_PRESSED"
  "FlashingRed on F_PRESSED"

  Red: {
    -- After 5s in Red, go to Green
    "Green after 5"
  }

  Green: {
    -- After 5s in Green, go to Yellow
    "Yellow after 5"
  }

  Yellow: {
    -- After 1s in Yellow, return to Red
    "Red after 1"
  }

  FlashingRed: {
    -- On entering FlashingRed, immediately go to FlashingRedOn
    default: "FlashingRedOn"

    -- After 5s in FlashingRed, transition back to Red
    "Red after 5"

    FlashingRedOn: {
      -- After 0.5s in FlashingRedOn, toggle to FlashingRedOff
      "FlashingRedOff after 0.5"
    }

    FlashingRedOff: {
      -- After 0.5s in FlashingRedOff, toggle back to FlashingRedOn
      "FlashingRedOn after 0.5"
    }
  }
}

-- Define a Stoplight class that extends the HSM runtime.
class Stoplight extends create_hsm(stoplight_def)
  -- HSM-level actions.
  onHSMEntry: => print "stoplight started"
  onHSMUpdate: (dt) =>
  onHSMExit: => print "stoplight stopped"

  -- Red state actions.
  onRedEntry: => print "red light ON"
  onRedUpdate: (dt) =>
  onRedExit: => print "red light OFF"

  -- FlashingRed state actions.
  onFlashingRedEntry: =>
  onFlashingRedUpdate: (dt) =>
  onFlashingRedExit: =>

  -- FlashingRedOn state actions.
  onFlashingRedOnEntry: => print "red light ON"
  onFlashingRedOnUpdate: (dt) =>
  onFlashingRedOnExit: => print "red light OFF"

  -- FlashingRedOff state actions.
  onFlashingRedOffEntry: =>
  onFlashingRedOffUpdate: (dt) =>
  onFlashingRedOffExit: =>

  -- Yellow state actions.
  onYellowEntry: => print "yellow light ON"
  onYellowUpdate: (dt) =>
  onYellowExit: => print "yellow light OFF"

  -- Green state actions.
  onGreenEntry: => print "green light ON"
  onGreenUpdate: (dt) =>
  onGreenExit: => print "green light OFF"

-- Instantiate the stoplight HSM.
stoplight = Stoplight!

-- Set up non-blocking input.
getch = require "lua-getch"
getch.set_raw_mode io.stdin
getch.set_nonblocking io.stdin, true

-- Main loop parameters.
dt = 0.05
while stoplight\update dt
  key = getch.get_char io.stdin
  switch key
    when 102 then stoplight\trigger "F_PRESSED"
    when 103 then stoplight\trigger "G_PRESSED"
    when 113 then stoplight\trigger "Q_PRESSED"
    when 114 then stoplight\trigger "R_PRESSED"
    when 121 then stoplight\trigger "Y_PRESSED"
  os.execute "sleep #{dt}"
