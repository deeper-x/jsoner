const std = @import("std");
const json = std.json;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
    const allocator = gpa.allocator();

    const file_path = "./src/assets/in_file.txt";

    try writeFile(file_path, "Hello, Zig!\n");

    const content = try readFile(allocator, file_path);
    defer allocator.free(content);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("File Content: {s}", .{content});

    const large_file = "./src/assets/large_file.txt";
    try readBigFile(large_file);

    try streamBigFile(allocator, large_file, 1024);
}

fn writeFile(file_path: []const u8, data: []const u8) !void {
    const file = try std.fs.cwd().createFile(file_path, .{});
    defer file.close();

    try file.writeAll(data);
}

fn readFile(allocator: std.mem.Allocator, file_path: []const u8) ![]u8 {
    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    const file_size = try file.getEndPos();

    const buffer = try allocator.alloc(u8, file_size);

    _ = try file.readAll(buffer);

    return buffer;
}

pub fn readBigFile(file_path: []const u8) !void {
    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        try std.io.getStdOut().writer().print("{s}\n", .{line});
    }
}

pub fn streamBigFile(allocator: std.mem.Allocator, in_file: []const u8, chunk_size: usize) !void {
    const file = try std.fs.cwd().openFile(in_file, .{});
    defer file.close();

    const file_size = try file.getEndPos();

    var buffer = try allocator.alloc(u8, chunk_size);
    defer allocator.free(buffer);

    var content = std.ArrayList(u8).init(allocator);
    defer content.deinit();

    var total_bytes_read: usize = 0;
    while (total_bytes_read < file_size) {
        const bytes_to_read = @min(chunk_size, file_size - total_bytes_read);

        const bytes_read = try file.readAll(buffer[0..bytes_to_read]);
        if (bytes_read == 0) break; // End of file

        const chunk = buffer[0..bytes_read];
        try content.appendSlice(chunk);
        total_bytes_read += bytes_read;

        try std.io.getStdOut().writer().print("{s}\n", .{buffer});
    }
}
