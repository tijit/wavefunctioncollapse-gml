# gml-wavefunctioncollapse
its wave function collapse in gml (images only, no tiles)

YYC and GMRT compatible, seems to be fastest with GMRT

usage:

`plist = new wfcReadImage(spriteIndex, periodic, N);`

parses a sprite into NxN patterns and returns it an instance of `wfcPatternList` 

`wave = new wfcWave(plist, width, height);`

make a new unsolved canvas

`wave.propagate();`

do one step of the algorithm. returns 0 when complete, 1 if still going, 2 if it failed

see `RunnerSimple` for necessary draw calls

see `Runner` for advanced use & examples (the default when running, has on-screen instructions)

see `example image sources` for example image sources

---

i kind of just wrote how i thought this would work in my head based on videos i watched, to see a good implementation go here: [https://github.com/mxgmn/WaveFunctionCollapse/tree/master](https://github.com/mxgmn/WaveFunctionCollapse/tree/master)

i made a few Decisions based around what is fast in GML vs other languages
