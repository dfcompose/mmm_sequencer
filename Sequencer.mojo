from mmm_audio import *
from seq import *
from EightOhEight import *



struct Sequencer(Movable, Copyable):
    var poly: Poly
    var world: World
    var hi_hat: List[HiHat]
    var snare : List[Snare]
    var kick : List[Kick]
    var messenger: Messenger
    var clock : Pointer[Clock, MutUntrackedOrigin]
    var hi_hat_stream : Pointer[Stream, MutUntrackedOrigin]
    var snare_stream : Pointer[Stream, MutUntrackedOrigin]
    var kick_stream : Pointer[Stream, MutUntrackedOrigin]
    def __init__(out self, world: World):
        self.world = world
        self.messenger = Messenger(self.world)
        self.poly = Poly(self.world, 128, "poly")
        self.hi_hat = [HiHat(self.world) for _ in range(128)]
        self.snare = [Snare(self.world) for _ in range(128)]
        self.kick = [Kick(self.world) for _ in range(128)]
        self.clock = Clock.make_clock(world)
        self.hi_hat_stream = Stream.make_stream(world, self.clock, namespace="hi_hat")
        self.snare_stream = Stream.make_stream(world, self.clock, namespace="snare")
        self.kick_stream = Stream.make_stream(world, self.clock, namespace="kick")
        self.hi_hat_stream[].set_event("deltas", Dseq([0.25, 0.25], None))
        # self.snare_stream[].events["deltas"] = Pseq([1.0], None)
        # self.snare_stream[].events["amp"] = Pseq([0.0, 0.5], None)
        # self.kick_stream[].events["deltas"] = Pseq([0.25, 0.25], None)
        # self.kick_stream[].events["amp"] = Pseq([0.5, 0.0], None)
        
        self.clock[].set_tempo(60)
        pass
 
    def next(mut self) raises -> MFloat[2]:
        
        
        
        self.clock[].tick()
        
        if self.hi_hat_stream[].next():

            var vox = self.poly.next_trig(self.hi_hat, True)
           
            
            if vox >= 0:
                
                self.hi_hat[vox].trigger = True
                self.hi_hat[vox].phase = 0
                self.hi_hat[vox].dur = self.hi_hat_stream[].out["dur"]
                self.hi_hat[vox].vol = self.hi_hat_stream[].out["amp"]

        
        if self.snare_stream[].next():
           
            var vox = self.poly.next_trig(self.snare, True)
           
            
            if vox >= 0:
                
                self.snare[vox].active = True
                self.snare[vox].phase = 0
                self.snare[vox].dur = self.snare_stream[].out["dur"]
                self.snare[vox].vol = self.snare_stream[].out["amp"]
        
        
        if self.kick_stream[].next():
            
            var vox = self.poly.next_trig(self.kick, True)
           
            
            if vox >= 0:
                
                self.kick[vox].active = True
                self.kick[vox].phase = 0
                self.kick[vox].dur = self.kick_stream[].out["dur"]
                self.kick[vox].vol = self.kick_stream[].out["amp"]



        var out = MFloat[2](0.0)

        for ref voice in self.hi_hat:
            out += voice.next()
        
        for ref voice in self.snare:
            out += voice.next()
        
        for ref voice in self.kick:
            out += voice.next()
        return out

       
