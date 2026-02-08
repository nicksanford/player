const std = @import("std");
const run = @import("player").run;

pub fn main() anyerror!void {
    try run();
}
