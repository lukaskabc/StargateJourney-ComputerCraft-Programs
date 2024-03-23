return {
    NONE = {code = 0, description = "No feedback"},
    UNKNOWN_ERROR = {code = -1, description = "An unknown error occurred"},

    -- symbols
    SYMBOL_ENCODED = {code = 1, description = "Symbol encoded"},
    SYMBOL_IN_ADDRESS = {code = -2, description = "Symbol in address"},
    SYMBOL_OUT_OF_BOUNDS = {code = -3, description = "Symbol out of bounds"},
    ENCODE_WHEN_CONNECTED = {code = -4, description = "encode_when_connected"},

    -- connection
    CONNECTION_ESTABLISHED_SYSTEM_WIDE = {code = 2, description = "Connection established system wide"},
    CONNECTION_ESTABLISHED_INTERSTELLAR = {code = 3, description = "Connection established interstellar"},
    CONNECTION_ESTABLISHED_INTERGALACTIC = {code = 4, description = "Connection established intergalactic"},

    -- errors
    INCOMPLETE_ADDRESS = {code = -5, description = "Incomplete address"},
    INVALID_ADDRESS = {code = -6, description = "Invalid address"},
    NOT_ENOUGH_POWER = {code = -7, description = "Not enough power"},
    SELF_OBSTRUCTED = {code = -8, description = "Self obstructed"},
    TARGET_OBSTRUCTED = {code = -9, description = "Target obstructed"},
    SELF_DIAL = {code = -10, description = "Self dial"},
    SAME_SYSTEM_DIAL = {code = -11, description = "Same system dial"},
    ALREADY_CONNECTED = {code = -12, description = "Already connected"},
    NO_GALAXY = {code = -13, description = "No galaxy"},
    NO_DIMENSIONS = {code = -14, description = "No dimensions"},
    NO_STARGATES = {code = -15, description = "No stargates"},
    TARGET_RESTRICTED = {code = -16, description = "Target restricted"},
    INVALID_8_CHEVRON_ADDRESS = {code = -17, description = "Invalid 8 chevron address"},
    INVALID_SYSTEM_WIDE_CONNECTION = {code = -18, description = "Invalid system wide connection"},

    -- end of connection
    CONNECTION_ENDED_BY_DISCONNECT = {code = 7, description = "Connection ended by disconnect"},
    CONNECTION_ENDED_BY_POINT_OF_ORIGIN = {code = 8, description = "Connection ended by point of origin"},
    CONNECTION_ENDED_BY_NETWORK = {code = 9, description = "Connection ended by network"},
    CONNECTION_ENDED_BY_AUTOCLOSE = {code = 10, description = "Connection ended by autoclose"},
    EXCEEDED_CONNECTION_TIME = {code = -19, description = "Exceeded connection time"},
    RAN_OUT_OF_POWER = {code = -20, description = "Ran out of power"},
    CONNECTION_REROUTED = {code = -21, description = "Connection rerouted"},
    WRONG_DISCONNECT_SIDE = {code = -22, description = "Wrong disconnect side"},
    CONNECTION_FORMING = {code = -23, description = "Connection forming"},

    STARGATE_DESTROYED = {code = -24, description = "Stargate destroyed"},
    COULD_NOT_REACH_TARGET_STARGATE = {code = -25, description = "Could not reach target stargate"},
    INTERRUPTED_BY_INCOMING_CONNECTION = {code = -26, description = "Interrupted by incoming connection"},

    -- milky way gate specific
    CHEVRON_RAISED = {code = 11, description = "Chevron raised"},
    ROTATING = {code = 12, description = "Rotating"},
    ROTATION_BLOCKED = {code = -27, description = "Rotation blocked"},
    NOT_ROTATING = {code = -28, description = "Not rotating"},
    ROTATION_STOPPED = {code = 13, description = "Rotation stopped"},
    CHEVRON_ALREADY_OPENED = {code = -29, description = "Chevron already opened"},
    CHEVRON_ALREADY_CLOSED = {code = -30, description = "Chevron already closed"},
    CHEVRON_NOT_RAISED = {code = -31, description = "Chevron not raised"},
    CANNOT_ENCODE_POINT_OF_ORIGIN = {code = -32, description = "Cannot encode point of origin"}
}