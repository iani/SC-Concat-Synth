//   3 May 2017 22:49
// Testing just single not-resettable synth approach with env.
// With better sample to see accuracy

//: record test buffer with an ascending sine wave.
{
	var sound;
	Server.default.prepareForRecord;
	0.1.wait;
	{
		SinOsc.ar (Line.kr (300, 3000, 3), 0, 0.1)
	}.play;
	0.1.wait;
	Server.default.record;
	1.wait;
	Server.default.stopRecording;
	"done".postln;
}.fork;
//: load test buffer 

// This has been moved to ./serverActions
// ~buffer = Buffer.read(Server.default, "./sample2.aiff");

//: Test buffer
~buffer.play;

//: start with simple BufRd synth
// From help file
{ BufRd.ar(1, ~buffer, Phasor.ar(0, BufRateScale.kr(~buffer), 0, BufFrames.kr(~buffer))) }.play;

//: mod 1: Use line instead of phasor
{ BufRd.ar(1, ~buffer,
	Line.ar(0, BufFrames.kr(~buffer) * 0.75, 0.75))
}.play;

//: Adapt this for playing with BufRd

SynthDef("argenvbuf", { | gate = 1 |
	var env, envctl;
	// make a dummy 80 segment envelope
	env = Env.newClear(80);
	
	// create a control argument array
	envctl = Control.names([\env]).kr( env.asArray );
	Out.ar(0,
		BufRd.ar (1, ~buffer,
			EnvGen.ar (envctl, gate: gate, doneAction: 0)));
}).add

//:
~synth = Synth ("argenvbuf", [env: Env ([0, 44000, 0], [1, 1])]);

~synth = Synth ("argenvbuf", [env: Env ([0, 44000, 0, 22000], [1, 0, 0.5])]);
//:
~synth = Synth ("argenvbuf", [env: Env (
	[0, 44000, 0, 22000, 11000, 33000, 44000, 11000],
	[1, 0, 0.5, 0, 1, 0, 5])]);

//:
~synth = Synth ("argenvbuf", [env: Env (
	[0, 44000, 0, 22000, 11000, 33000, 44000, 11000],
	[1, 0, 0.5, 0, 1, 0, 5] / 4)]);

//:
~synth.set (\gate, 0);

//:
~synth.set (\gate, 1);

//:
~synth.set (\gate, 0);

//:
~synth.set ([env: Env ([0, 22000, 0, 44000], [1, 0, 0.5]), gate: 1]);

//: Next: Use Changed.kr instead of setting gate to 0 then 1 explicitly

SynthDef ("changetest", { | change = 0 |
	var env;
	env = Env.perc;

	Out.ar (0, WhiteNoise.ar (0.1) * EnvGen.kr (env, gate: Changed.kr (change), doneAction: 0))
}).add;

//: Variant above to test different envelope

SynthDef ("changetest2", { | change = 0 |
	var env;
	env = Env ([0, 0.2, 0], [0.01, 0.1]);

	Out.ar (0, WhiteNoise.ar (0.1) * EnvGen.kr (env, gate: Changed.kr (change), doneAction: 0))
}).add;

//: Variant above to test same envelope with BufRd

SynthDef ("changetest3", { | change = 0 |
	var env;
	env = Env ([0, 44000], [1]);

	Out.ar (0,
		BufRd.ar(2, ~buffer,
			EnvGen.ar (env, gate: Changed.kr (change), doneAction: 0)))
}).add;

//: testing

~test = Synth ("changetest3");

~test.set (\change, 2);

//: testing 2
{
	var synth, stream;
	synth = Synth ("changetest3");
	stream = Pseries (1, 1, inf).asStream;
	500 do: {
		[1.5].choose.wait;
		synth.set (\change, stream.next);
	}
}.fork; // OK, fine

//: Try out basic env for BuRd

~buffer = Buffer.read(Server.default, "sample.aiff");

//:
~buffer.numFrames;

~buffer.play;
//:

{
	var env;
	env = Env ([0, ~buffer.numFrames], [~buffer.numFrames / 44100]);
	BufRd.ar(
		2, ~buffer,
		EnvGen.ar (env, 1, doneAction: 2)
	)
}.play

//: Convert above into a synthdef

SynthDef ("trigbufrdenv", { | buf |
	var env;
	env = Env ([0, buf.numFrames], [buf.numFrames / 44100]);
	BufRd.ar(
		2, buf,
		EnvGen.ar (env, 1, doneAction: 2)
	)
});

//: First try for a SynthDef that uses BufRd with Env

SynthDef ("bufrdenv", { | buf, change = 0 |
	var env, envctl;
	env = Env.newClear (80);
	envctl = Control.names ([\env]).kr (env.asArray);
	Out.kr (0,
		BufRd.ar (2, buf, EnvGen.ar (envctl, gate: Changed.kr (change), doneAction: 0))
	);
}).add;

//:

~synth = Synth ("bufrdenv", [buf: ~buffer]);

//:

~synth.set (\env, Env ([0, ~buffer.numFrames], [~buffer.numFrames / 44100]).asArray);
~synth.set (\change, 1);

