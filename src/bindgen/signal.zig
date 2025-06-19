pub const Signal = union(enum) {
    ping: fn () void,
    pong: fn () void,
};
