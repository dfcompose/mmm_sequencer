from mmm_audio import *

struct HiHat(PolyObject):
    """
    Based on TR 808.
    """
    var world: World
    var synth: PinkNoise[1]
    var oscs: Array[Osc[1], 6]
    var osc_freqs : MFloat[8]
    var freq: Float64
    var dur: Float64
    var vol: Float64
    var active: Bool
    var env : Array[Tuple[Float64, Float64], 4]
    # var env_params: EnvParams
    var trigger : Bool
    var event : List[Float64]
    var phase : MFloat[1]
    var filt : Reson[1]
    var filt_2 : Reson[1]
    var filt_3 : SVF[1]
    var q : Float64
    def __init__(out self, world: World):
        self.world = world
        self.freq = 440 * 4
        self.dur = 1
        self.vol = 0.5
        self.synth  = PinkNoise[1]()
        self.active = False
        self.env : Array[Tuple[Float64, Float64], 4] = [(0.0, 0.0), (0.01, 1.0), (0.050, 0.0), (1.0, 0.0)]
        self.osc_freqs = MFloat[8](800, 540, 523, 370, 304, 205, 0.0, 0.0)
        self.oscs = Array[Osc[1], 6](fill=Osc[1](world))
        self.trigger = False
        self.event = List[Float64]()
        self.phase = MFloat[1](0.0)
        self.filt = Reson[1](world)
        self.filt_2 = Reson[1](world)
        self.filt_3 = SVF[1](world)
        self.q = 1.0

    def check_active(mut self) -> Bool:
        return self.trigger

    def set_gate(mut self, trigger: Bool):
        
        self.trigger = trigger
        
        self.phase = 0.0


    def next(mut self) -> Float64:
        if self.trigger:
            # var env = self.env.next(self.trigger)
            var out = MFloat[1](0.0)
            
            var env = env[win_type=WindowType.sine, interp=Interp.linear](self.world, self.phase, self.env, 1.0) * self.vol
            

            comptime for i in range(6):
                out += self.oscs[i].next[OscType.square](self.osc_freqs[i])
            
            var filt_1 = self.filt.bpf(out, 7100, 5.0, 1.0)
            var filt_2 = self.filt_2.bpf(out, 3440, 5.0, 1.0)

            var sig = self.filt_3.hpf(filt_1 + filt_2, 7000, 1.0)
            
            
            self.phase += 1.0/self.world[].sample_rate
            self.trigger = self.phase <= 1.0
            return sig * self.vol * env
        else:
            
            return MFloat[1](0.0)


struct Snare(PolyObject):
    """
    Based on the TR-808.
    """
    var world: World
    var synth: PinkNoise[1]
    var oscs: List[Osc[1]]
    var freq: Float64
    var dur: Float64
    var vol: Float64
    var active: Bool
    var env : Array[Tuple[Float64, Float64], 4]
    var noise : WhiteNoise[1]
    # var env_params: EnvParams
    var trigger : Bool
    var event : List[Float64]
    var phase : MFloat[1]
    var filt : SVF[1]
    var q : Float64
    def __init__(out self, world: World):
        self.world = world
        self.freq = 440 * 4
        self.dur = 1
        self.vol = 0.5
        self.synth  = PinkNoise[1]()
        self.active = False
        self.env : Array[Tuple[Float64, Float64], 4] = [(0.0, 0.0), (0.01, 1.0), (0.05, 1.0), (1.0, 0.0)]
        self.trigger = False
        self.event = List[Float64]()
        self.phase = MFloat[1](0.0)
        self.filt = SVF[1](world)
        self.oscs = [Osc[1](world), Osc[1](world)]
        self.noise = WhiteNoise[1]()
        self.q = 1.0

    def check_active(mut self) -> Bool:
        return self.active

    def set_gate(mut self, trigger: Bool):
        
        self.active = trigger
        
        self.phase = 0.0


    def next(mut self) -> Float64:
        if self.active:
            # var env = self.env.next(self.trigger)
            
            var osc_env = env[win_type=WindowType.sine, interp=Interp.linear](self.world, self.phase, self.env, 8.0)
            var noise_env = env[win_type=WindowType.sine, interp=Interp.linear](self.world, self.phase, self.env, 8.0)
            var out = 0.0
           
            out += self.oscs[0].next(476)
            out += self.oscs[0].next(238)
            var sig = self.filt.hpf(self.noise.next(), self.freq, 1.0) * noise_env
            sig += out * osc_env
            
            self.phase += 1.0/self.world[].sample_rate/self.dur
            self.active = self.phase <= 1.0
            return sig * self.vol 
        else:
            
            return MFloat[1](0.0)




struct Kick(PolyObject):
    var world: World
    
    
    var freq: Float64
    var dur: Float64
    var vol: Float64
    var active: Bool
    var env : Array[Tuple[Float64, Float64], 4]
    # var env_params: EnvParams
    var trigger : Bool
    var event : List[Float64]
    var phase : MFloat[1]
    var filt : Reson[1]
    var q : Float64
    def __init__(out self, world: World):
        self.world = world
        self.freq = 110
        self.dur = 1
        self.vol = 0.5
       
        self.active = False
        self.env : Array[Tuple[Float64, Float64], 4] = [(0.0, 0.0), (0.01, 1.0), (0.05, 1.0), (1.0, 0.0)]
        self.trigger = False
        self.event = List[Float64]()
        self.phase = MFloat[1](0.0)
        self.filt = Reson[1](world)
        
        self.q = 1.0

    def check_active(mut self) -> Bool:
        return self.active

    def set_gate(mut self, trigger: Bool):
        
        self.active = trigger
        
        self.phase = 0.0


    def next(mut self) -> Float64:
        if self.active:
            # var env = self.env.next(self.trigger)
            
            var env = env[win_type=WindowType.sine, interp=Interp.linear](self.world, self.phase, self.env, 8.0) * self.vol
            
            var sig = self.filt.bpf(env, 52, 8.0, 1.0)
            
            
            self.phase += 1.0/self.world[].sample_rate/self.dur
            self.active = self.phase <= 1.0
            return sig * self.vol
        else:
            
            return MFloat[1](0.0)





struct EightOhEight(Movable, Copyable):
    # var world: World
    # var drum_poly: Poly
    var snare_poly: Poly
    var snares : List[Snare]
    var kick_poly : Poly
    var kicks : List[Kick]
    var hi_hat_poly : Poly
    var hi_hats : List[HiHat]
    # var client : OSCClient
    var counter : Float64
    var world : World
    var messenger : Messenger
    def __init__(out self, world: World):

        self.hi_hat_poly = Poly(world, 8, "hi_hat_poly")
        self.snare_poly = Poly(world, 8, "snare_poly")
        self.kick_poly = Poly(world, 8, "kick_poly")

        self.hi_hats = []
        self.snares = []
        self.kicks = []

        # self.client = OSCClient([127,0,0,1], 57120)
        self.messenger = Messenger(world)
        self.counter = 0
        self.world = world

        
        for _ in range(8):
            self.hi_hats.append(HiHat(world))

        for _ in range(8):
            self.snares.append(Snare(world))
        
        for _ in range(8):
            self.kicks.append(Kick(world))

        pass
 
    def next(mut self) raises -> MFloat[2]:
        var out = MFloat[2](0.0)

        self.counter += 1

      
        def hh_callback(mut poly_object: HiHat, mut vals: List[Float64]) capturing -> None:
            
            
            
            if vals[2] > 0:
                
                poly_object.freq = vals[0]
                poly_object.dur = vals[1]
                poly_object.vol = vals[2] * 0.5
                poly_object.q = vals[3]
                # poly_object.env[1][0] = vals[3]
                # poly_object.env[2][0] = vals[4]
                

                
        # _ = self.spat.next()
        self.hi_hat_poly.next_mgate[call_back=hh_callback](self.hi_hats)
        


        def snare_callback(mut poly_object: Snare, mut vals: List[Float64]) capturing -> None:
            if vals[2] > 0:
                
                # poly_object.freq = vals[0]
                poly_object.dur = vals[1]
                poly_object.vol = vals[2] * 0.5
                
                # poly_object.env[1][0] = vals[3]
                # poly_object.env[2][0] = vals[4]
                

                
        # _ = self.spat.next()
        self.snare_poly.next_mgate[call_back=snare_callback](self.snares)

        

        def kick_callback(mut poly_object: Kick, mut vals: List[Float64]) capturing -> None:
            if vals[2] > 0:
                
                # poly_object.freq = vals[0]
                poly_object.dur = vals[1]
                poly_object.vol = vals[2] * 0.5
                
                # poly_object.env[1][0] = vals[3]
                # poly_object.env[2][0] = vals[4]
                

                
        # _ = self.spat.next()
        self.kick_poly.next_mgate[call_back=kick_callback](self.kicks)


        for ref voice in self.hi_hats:
            out += voice.next()

        for ref voice in self.snares:
            out += voice.next()

        for ref voice in self.kicks:
            out += voice.next()
        # var out = MFloat[2](0.0)
        return out