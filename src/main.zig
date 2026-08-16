// this codebase only aims to solve part 1, not 2.
const std = @import("std");

const motion = enum {
    L, R
};
const fileContainer = struct { char: motion, amount: u16 };
var global: u8 = 50;

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();

    const alloc = gpa.allocator();

    // get args
    const args = try init.minimal.args.toSlice(alloc);
    defer alloc.free(args);

    if (args.len < 2) return error.MissingArg;

    // grap everything from "file.txt"
    // carry them all into one giant dynamic array.
    // and then go through each entry of the array and run that using the global variable.

    var array: std.ArrayList(fileContainer) = .empty;
    defer array.deinit(alloc);

    // read through the whole file and on every line do an .append()

    const file = try std.Io.Dir.openFileAbsolute(
        io, args[1], .{},
    );
    defer file.close(io);

    // hope that no line will be longer than 4096 u8s
    var buff: [4096]u8 = undefined;
    var file_reader = file.reader(io, &buff);

    var container: fileContainer = undefined;
    while (try file_reader.interface.takeDelimiter('\n')) | raw_line | {

        const line = std.mem.trim(u8, raw_line, " \r\t");
        if (line.len == 0) continue;

        switch (line[0]) {
            'R' => container.char = motion.R,
            'L' => container.char = motion.L,
            else => return error.InvalidMotion,
        }

        const num: u16 = try std.fmt.parseInt(u16, line[1..], 10);
        container.amount = num;

        try array.append(alloc, container);
    }

    var zero_count: u64 = 0;

    // go through each iteration of array
    for (array.items) |value| {
        const temp: fileContainer = value;

        switch (temp.char) {
            motion.L => {
                const diff = @as(i32, global) - @as(i32, value.amount); 
                global = @intCast(@mod(diff, 100));
            },
            
            motion.R => {
                const diff = @as(i32, global) + @as(i32, value.amount); 
                global = @intCast(@mod(diff, 100));
            }, 
        }
        // now let me know how often `0` got hit
        if (global == 0) zero_count += 1;

    }
    std.debug.print("{d}\n", .{global});
    std.debug.print("{d}\n", .{zero_count});
}
