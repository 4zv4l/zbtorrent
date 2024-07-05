const std = @import("std");
const bencode = @import("bencode");
const Allocator = std.mem.Allocator;

pub const TorrentInfo = struct {
    announce: []const u8,
    infohash: [20]u8,
    pieces: [][20]u8,
    piece_length: i64,
    length: i64,
    name: []const u8,

    pub fn deinit(self: TorrentInfo, allocator: Allocator) void {
        allocator.free(self.pieces);
    }
};

// take the root of the Bencode structure (dictionnary)
// and calculate the SHA-1 sum of the info field
pub fn infohash(allocator: Allocator, root: bencode.Token) ![20]u8 {
    var hash: [20]u8 = undefined;
    var info_data = std.ArrayList(u8).init(allocator);
    defer info_data.deinit();

    if (root == .dictionnary) {
        if (root.dictionnary.get("info")) |info| {
            try info.encode(info_data.writer());
            std.crypto.hash.Sha1.hash(info_data.items, &hash, .{});
            return hash;
        }
        return error.NoInfoField;
    }
    return error.NotADictionnary;
}

// load all the pieces sha1 hashes
pub fn getPieces(allocator: Allocator, pieces: bencode.Token) ![][20]u8 {
    const raw_pieces: []const u8 = pieces.string;
    const pieces_array: [][20]u8 = try allocator.alloc([20]u8, raw_pieces.len / 20);
    errdefer allocator.free(pieces_array);

    var ptr: []const u8 = raw_pieces[0..];
    for (pieces_array) |*piece| {
        piece.* = [1]u8{0} ** 20;
        @memcpy(piece, ptr[0..@min(ptr.len, 20)]);
        ptr = ptr[20..];
    }

    return pieces_array;
}

// retrieve torrent file information
// all the returned data is duped so you can free the _root
pub fn getTorrentInfo(allocator: Allocator, _root: bencode.Token) !TorrentInfo {
    if (_root != .dictionnary) return error.NotADictionnary;
    const root = _root.dictionnary;
    const _info = root.get("info") orelse return error.NoInfo;
    if (_info != .dictionnary) return error.NotADictionnary;
    const info = _info.dictionnary;

    var t = TorrentInfo{
        .announce = (root.get("announce") orelse return error.NoAnnounce).string,
        .infohash = try infohash(allocator, _root),
        .pieces = undefined,
        .piece_length = (info.get("piece length") orelse return error.NoName).integer,
        .length = (info.get("length") orelse return error.NoLength).integer,
        .name = (info.get("name") orelse return error.NoName).string,
    };
    t.pieces = try getPieces(allocator, info.get("pieces") orelse return error.NoPieces);
    return t;
}
