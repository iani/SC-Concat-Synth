// Here developing the code bottom-up step by step,
// based on examples from help files and elsewhere
//  2 May 2017 15:18


//: record test buffer
{
	var sound;
	Server.default.prepareForRecord;
	0.1.wait;
	Server.default.record;
	0.1.wait;

	(0..10) do: { | degree |
		(degree: degree, dur: 0.1).play;
		0.1.wait;
	};
	
	Server.default.stopRecording;
}.fork;
//: load test buffer 

~buffer = Buffer.read(Server.default, "./sample.aiff");

//: Test buffer
~buffer.play;

//: start with simple BufRd synth
// From help file
{ BufRd.ar(2, ~buffer, Phasor.ar(0, BufRateScale.kr(~buffer), 0, BufFrames.kr(~buffer))) }.play;

//: mod 1: Use line instead of phasor
{ BufRd.ar(2, ~buffer,
	Line.ar(0, BufFrames.kr(~buffer) * 0.75, 0.7
		5))
}.play;

//: mod 2: Use envelope
// stage 1: Start from help file
// From: http://danielnouri.org/docs/SuperColliderHelp/UGens/Synth%20control/Envelopes/EnvGen.html
SynthDef("env", { arg i_outbus=0;
	var env, envctl;
	
	// make a dummy 8 segment envelope
	env = Env.newClear(8);
	
	// create a control argument array
	envctl = Control.names([\env]).kr( env.asArray );
	
	ReplaceOut.kr(i_outbus, EnvGen.kr(envctl, doneAction: 2));
}).send(s);

//:	

SynthDef("sine", {
	Out.ar(0, SinOsc.ar(In.kr(0), 0, 0.2));
}).send(s);
//:

s.sendMsg(\c_set, 0, 800);

s.sendMsg(\s_new, \sine, 1001, 1, 0);

e = Env([700,900,900,800], [1,1,1]*0.4, \exp).asArray;
s.sendBundle(nil,[\s_new, \env, 1002, 2, 1001],[\n_setn, 1002, \env, e.size] ++ e);

f = Env([1000,1000,800,1000,900,1000], [1,1,1,1,1]*0.3, \step).asArray;
s.sendBundle(nil,[\s_new, \env, 1003, 2, 1001],[\n_setn, 1003, \env, f.size] ++ f);

s.sendMsg(\n_free, 1001);

//: mod 2 step b: Test custom envelope on synth directly

SynthDef("argenvsine", {
	var env, envctl;
	// make a dummy 8 segment envelope
	env = Env.newClear(80);
	
	// create a control argument array
	envctl = Control.names([\env]).kr( env.asArray );
	Out.ar(0, SinOsc.ar(EnvGen.kr (envctl, doneAction: 2), 0, 0.2));
}).add

//: Testing mod 2 step b, single synths

Synth ("argenvsine", [env: Env ([60, 65, 63, 72, 72].midicps, [1, 1, 1, 3], \sine)]);

Synth ("argenvsine", [env: Env ([60, 65, 63, 72, 72].midicps, [1, 1, 1, 3], \hold)]);

Synth ("argenvsine", [env: Env ((60..72).midicps, 0.25 ! 12, \step)]);

//: Testing mod 2 step b, restarting env on running synth

SynthDef("argenvsine2", {
	var env, envctl;
	// make a dummy 80 segment envelope
	env = Env.newClear(80);
	
	// create a control argument array
	envctl = Control.names([\env]).kr( env.asArray );
	Out.ar(0, SinOsc.ar(EnvGen.kr (envctl, doneAction: 0), 0, 0.2));
}).add

//: Here is the synth

~test = Synth ("argenvsine2", [env: Env ((60..72).midicps, 0.25 ! 12, \step)]);

//:

~test.set (\env, (Env((60..72).midicps, 0.25 ! 12, \step).asArray));

//: I think we need a trigger to reset the envelope

SynthDef("argenvsine2", { | gate = 1 |
	var env, envctl;
	// make a dummy 80 segment envelope
	env = Env.newClear(80);
	
	// create a control argument array
	envctl = Control.names([\env]).kr( env.asArray );
	Out.ar(0, SinOsc.ar(EnvGen.kr (envctl, gate: gate, doneAction: 0), 0, 0.2));
}).add

//: testing version with gate

~test = Synth ("argenvsine2", [env: Env ((60..72).midicps, 0.25 ! 12, \step)]);

~test.set (\gate, 0);

~test.set (\gate, 1;)

~test.set (\env, (Env((60..72).midicps.reverse, 0.1 ! 12, \step).asArray), \gate, 0);

~test.set (\gate, 1;)

//: Adapt this for playing with BufRd

SynthDef("argenvbuf", { | gate = 1 |
	var env, envctl;
	// make a dummy 80 segment envelope
	env = Env.newClear(80);
	
	// create a control argument array
	envctl = Control.names([\env]).kr( env.asArray );
	Out.ar(0,
		BufRd.ar (2, ~buffer,
			EnvGen.ar (envctl, gate: gate, doneAction: 0)));
}).add

//:
~synth = Synth ("argenvbuf", [env: Env ([0, 44000, 0], [1, 1])]);

~synth = Synth ("argenvbuf", [env: Env ([0, 44000, 0, 22000], [1, 0, 0.5])]);

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

