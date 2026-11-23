from mmm_audio import *
from std.utils import Variant




struct Clock(Movable, Copyable):
    var world : World
    var tempo : Float64
    var meter : Int
    var beat : Int
    var bar : Int
    var temp_to_samps : Int
    var elapsed_samps : Int
    var streams : List[MutPointer[Stream, MutUntrackedOrigin]]
    

    @staticmethod
    def make_clock(world : World, tempo : Float64 = 60,  meter : Int = 4) -> Pointer[mut=True, Clock, MutUntrackedOrigin]:
        var clock_ptr = unsafe_alloc[Clock](1)
        clock_ptr.unsafe_write(Clock(world, tempo, meter))
        return clock_ptr

    def __init__(out self, world: World, tempo : Float64 = 60, meter : Int = 4):
        self.world = world
        self.meter = meter
        self.tempo = tempo
        self.beat = 0
        self.bar = 0
        self.temp_to_samps = Int(self.world[].sample_rate * (60/self.tempo))
        self.elapsed_samps = 0
        self.streams = List[MutPointer[Stream, MutUntrackedOrigin]]()
        
        pass


    def set_tempo(mut self, new_tempo : Float64) -> None:
        self.tempo = new_tempo
        self.temp_to_samps = Int(self.world[].sample_rate * (60/self.tempo))


    def tick(mut self) raises -> None:
        var new_beat = False
        var new_bar = False

        if self.temp_to_samps - self.elapsed_samps == 0:
            self.elapsed_samps = 0
            self.beat += 1
            new_beat = True
            if not self.beat % self.meter:
                new_bar = True
                self.bar += 1
        else:
            self.elapsed_samps += 1
        
        if new_beat:
            
            for ref stream in self.streams:
                stream[].on_new_beat()

        if new_bar:
            for ref stream in self.streams:
                stream[].on_new_bar()

        

        pass


struct Stream(Movable, Copyable):
    var messenger: Messenger
    var events: Dict[String, Sequence]
    var next_bar: Dict[String, List[Float64]]
    var next_beat: Dict[String, List[Float64]] 
    var out : Dict[String, Float64]
    var delta_samps : Int
    var active : Bool
    var clock : Pointer[mut=True, Clock, MutUntrackedOrigin]

    @staticmethod
    def make_stream(world : World, clock : Pointer[mut=True, Clock, MutUntrackedOrigin], namespace : String = "stream") -> Pointer[mut=True, Stream, MutUntrackedOrigin]:
        var stream_ptr = unsafe_alloc[Stream](1)
        stream_ptr.unsafe_write(Stream(world, clock, namespace))
        clock[].streams.append(stream_ptr)
        return stream_ptr

    def __init__(out self, world : World, clock : Pointer[mut=True, Clock, MutUntrackedOrigin], namespace: String = "stream"):
        self.messenger = Messenger(world, namespace)
        self.delta_samps = 0
        self.events = {
            "deltas": Drand([1, 1, 1, 1]),
            "dur": Drand([0.5]),
            "freq": Drand([60]),
            "amp": Drand([0.25])
        }


        self.out = {}
        self.next_bar = {}
        self.next_beat = {}
        for key in self.events:
            self.out[key] = 0.0
            self.next_bar[key] = [-1]
            self.next_beat[key] = [-1]
        self.active = True
        self.clock = clock

    
    def on_new_beat(mut self) raises -> None:
        
        # Queued events are a list of floats with index 0 being the delta to execution, index 1 the sequence type, and indices 2:: or 3:: (for Dseq, 2 is the number of repeats) the values
        for key in self.next_beat:

            if self.next_beat[key][0] == 0:
                
                if self.next_beat[key][1] == 0:
                    var repeats : Optional[Float64] = None
                    if self.next_beat[key][2] < 0:
                        repeats = self.next_beat[key][2]
                    self.events[key] = Dseq(List[Float64](self.next_beat[key][3::]), repeats)
                elif self.next_beat[key][1] == 1:
                    print("New Beat")
                    self.events[key] = Drand(List[Float64](self.next_beat[key][2::]))
                self.next_beat[key][0] -= 1
            elif self.next_beat[key][0] > 0:
                self.next_beat[key][0] -= 1

    def on_new_bar(mut self) raises -> None:
        
        for key in self.next_bar:
            
            if self.next_bar[key][0] == 0:
                
                if self.next_bar[key][1] == 0:
                    var repeats : Optional[Float64] = None
                    if self.next_bar[key][2] < 0:
                        repeats = self.next_bar[key][2]
                    self.events[key] = Dseq(List[Float64](self.next_bar[key][3::]), repeats)
                elif self.next_bar[key][1] == 1:
                    self.events[key] = Drand(List[Float64](self.next_bar[key][2::]))
                self.next_bar[key][0] -= 1
            elif self.next_bar[key][0] > 0:
                self.next_bar[key][0] -= 1

    def set_event(mut self, key: String, pattern : Sequence) -> None:
        self.events[key] = pattern.copy()

    def get_next_val(mut self, key: String) raises -> Float64:
        if self.events[key].isa[Dseq]():
            return self.events[key].unsafe_get[Dseq]().next_val()

        return 0.0
    
    def scheduling(mut self) -> None:

        def sched_delta_bar(vals: List[Float64]) capturing -> None:
            
            self.next_bar["deltas"] = vals.copy()
            pass

        def sched_delta_beat(vals: List[Float64]) capturing -> None:
            
            self.next_beat["deltas"] = vals.copy()
            pass

        self.messenger.address_callback[sched_delta_bar]("deltas.next_bar")
        self.messenger.address_callback[sched_delta_beat]("deltas.next_beat")

        def sched_freq_bar(vals: List[Float64]) capturing -> None:
            
            self.next_bar["freq"] = vals.copy()
            pass

        def sched_freq_beat(vals: List[Float64]) capturing -> None:
            self.next_beat["freq"] = vals.copy()
            pass

        self.messenger.address_callback[sched_freq_bar]("freq.next_bar")
        self.messenger.address_callback[sched_freq_beat]("freq.next_beat")

    def next(mut self) raises -> Bool:
        self.scheduling()
       
        ## First value of list is 0 for Dseq or 1 for Drand, second value is num repeats (inf if <= 0)
        def on_deltas_change(vals: List[Float64]) capturing -> None:
            var repeat : Optional[Float64] = None

            if vals[1] > 0:
                repeat = vals[1]
        
            if vals[0] == 0:
                self.events["deltas"] = Dseq(List[Float64](vals[2::]), repeat)
            elif vals[0] == 1:
                self.events["deltas"] = Drand(List[Float64](vals[2::]), repeat)
        
        self.messenger.address_callback[on_deltas_change]("deltas.change")
        
        def on_dur_change(vals: List[Float64]) capturing -> None:
            if vals[0] == 0:
                self.events["dur"] = Dseq(List[Float64](vals[1::]))
            elif vals[0] == 1:
                self.events["dur"] = Drand(List[Float64](vals[1::]))
        
        self.messenger.address_callback[on_dur_change]("dur.change")

        
        def on_amp_change(vals: List[Float64]) capturing -> None:
            if vals[0] == 0:
                self.events["amp"] = Dseq(List[Float64](vals[1::]))
            elif vals[0] == 1:
                self.events["amp"] = Drand(List[Float64](vals[1::]))
        
        self.messenger.address_callback[on_amp_change]("amp.change")


        def on_freq_change(vals: List[Float64]) capturing -> None:
            if vals[0] == 0:
                self.events["freq"] = Dseq(List[Float64](vals[1::]))
            elif vals[0] == 1:
                self.events["freq"] = Drand(List[Float64](vals[1::]))
        
        self.messenger.address_callback[on_freq_change]("freq.change")

        
        if self.active:
            
            
            if self.events["deltas"].isa[Dseq]():
                if not self.events["deltas"].unsafe_get[Dseq]().active:
                    return False
            

            if Int(Float64(self.clock[].temp_to_samps) * self.out["deltas"]) - self.delta_samps <= 0:
                self.delta_samps = 0
                
                for key in self.events:
 
                    if self.events[key].isa[Dseq]():
                        self.out[key] = self.events[key].unsafe_get[Dseq]().next()
                    elif self.events[key].isa[Drand]():
                        self.out[key] = self.events[key].unsafe_get[Drand]().next()
                
                
                return True

            self.delta_samps += 1
            
            return False
        else:
            
            return False



comptime Sequence = Variant[Dseq, Drand]

struct Dseq(Movable, Copyable):
    var seq: List[Float64]
    var current_index: Int
    var value: Float64
    var repeats : Optional[Float64]
    var active : Bool
    def __init__(out self, seq : List[Float64], repeats : Optional[Float64] = None):
        
        self.seq = seq.copy()
        self.current_index = 0
        self.value = self.seq[0]
        self.repeats = repeats
        self.active = True
        pass

    def next_val(mut self) -> Float64:
        return self.seq[(self.current_index + 1) % (len(self.seq) - 1)]

    def next(mut self) -> Float64:
        var out : Float64 = self.seq[self.current_index % (len(self.seq))]

        if self.active:
            self.current_index += 1
            if not self.current_index % len(self.seq):
                if self.repeats:
                    self.repeats.value() -= 1
                    if self.repeats.value() <= 0:
                        self.active = False
                
        
        self.value = out
        return out

struct Drand(Movable, Copyable):
    var seq: List[Float64]
    var value: Float64
    var repeats : Optional[Float64]
    def __init__(out self, seq : List[Float64], repeats : Optional[Float64] = None):
        self.seq = seq.copy()
        self.value = self.seq[0]
        self.repeats = repeats
        pass


    def next(mut self) -> Float64:
        var out : Float64 = self.seq[random_si64(0, Int64((len(self.seq) -1)))]
        self.value = out
        
        return out