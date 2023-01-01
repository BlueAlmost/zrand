const std = @import("std");
const print = std.debug.print;
const math = std.math;
const Complex = std.math.complex.Complex;

const zrand = @import("zrand");

fn ValueType(comptime T: type) type {
    switch(T) {

        u8, []u8, => {return u8;},
        u16, []u16, => {return u16;},
        u32, []u32, => {return u32;},
        u64, []u64, => {return u64;},
        usize, []usize => {return usize;},

        i8, []i8, => {return i8;},
        i16, []i16, => {return i16;},
        i32, []i32, => {return i32;},
        i64, []i64, => {return i64;},

        f32, Complex(f32) => {return f32;},
        f64, Complex(f64) => {return f64;},
        []f32, []Complex(f32) => {return f32;},
        []f64, []Complex(f64) => {return f64;},
        else => {@compileError("type not implemented");}
    }
}

fn isComplex(comptime T: type) bool {
    switch(T) {
        []u8, []u16, []u32, []u64, []usize, []i8, []i16, []i32, []i64 => { return false;},
        []f32, []f64 => { return false; },
        []Complex(f32), []Complex(f64) => { return true; },
        else => {@compileError("type not implemented");},
    }
}

pub fn randn(rnd: std.rand.Random, x: anytype ) void {

    const T = @TypeOf(x);
    comptime var isCmpx: bool = isComplex(T);
    comptime var V: type = ValueType(T);

    var r: V      = undefined;
    var v1: V     = undefined;
    var v2: V     = undefined;
    var theta: V  = undefined;
    var i: usize  = 0;
    var n: usize  = x.len;

    switch (isCmpx) {

        false => {
            var n2: usize = n/2;
            while( i<n2 ) : ( i += 1 ) {
                v1 = rnd.float(V);
                v2 = rnd.float(V);
                r = math.sqrt(-2.0 * math.ln(v1));
                theta = 2.0 * math.pi * v2;
                x[2*i] = r * @cos(theta);
                x[2*i+1] = r * @sin(theta);
            }

            // compute last point if we had odd length of x
            if( 2 * n2 < n) {
                v1 = rnd.float(V);
                v2 = rnd.float(V);
                r = math.sqrt(-2.0 * math.ln(v1));
                theta = 2.0 * math.pi*v2;
                x[n-1] = r * @cos(theta);
            }
        },

        true => {
            while( i<n ) : ( i+=1 ) {
                v1 = rnd.float(V);
                v2 = rnd.float(V);
                r = math.sqrt1_2 * math.sqrt(-2.0*math.ln(v1));
                theta = 2.0 * math.pi*v2;
                x[i].re = r * @cos(theta);
                x[i].im = r * @sin(theta);
            }
        },
    }
}

pub fn rand(rnd: std.rand.Random, x: anytype ) void {

    const T = @TypeOf(x);
    comptime var isCmpx: bool = isComplex(T);
    comptime var V: type = ValueType(T);

    switch (isCmpx) {

        false => {

            switch(T) {
                []u8, []u16, []u32, []u64, []i8, []i16, []i32, []i64 => {
                    for (x) |_, i| { x[i] = rnd.int(V); }
                },

                []f32, []f64 => {
                    for (x) |_, i| { x[i] = rnd.float(V); }
                },
                else => { @compileError("type is not implmented");},
            }
        },

        true => {
            for (x) |_, i| {
                x[i].re = rnd.float(V);
                x[i].im = rnd.float(V);
            }
        },

    }
}

//--- TESTS ----------------------------------------------------------

test "\t randn \t real array\n" {
    inline for (.{f32, f64}) |T| {

        const n = 3;

        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const allocator = arena.allocator();

        var rnd0 = std.rand.DefaultPrng.init(42);
        // var rnd1 = std.rand.DefaultPrng.init(42); // can use multiple rng's with this
        var x = try allocator.alloc(T, n);

        randn(rnd0.random(), x);

        print("\n", .{});
        for (x) |xval| {
            print("\t{e:>10.3}\n", .{xval});
        }
    }
}


test "\t randn \t complex array\n" {
    inline for (.{f32, f64}) |T| {

        const C = Complex(T);

        const n = 3;

        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const allocator = arena.allocator();

        var rnd0 = std.rand.DefaultPrng.init(42);
        var x = try allocator.alloc(C, n);

        randn(rnd0.random(), x);

        print("\n", .{});
        for (x) |xval| {
            print("\t({e:>10.3}, {e:>10.3})\n", .{xval.re, xval.im});
        }
    }
}

