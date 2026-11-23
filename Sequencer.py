from mmm_python import *
from user.Pbind import *

maj_pent = [0, 2, 4, 7, 9]
min_pent = [0, 3, 5, 7, 10, 12]

maj = [0, 2, 4, 5, 7, 9, 11]
minor = [0, 2, 3, 5, 7, 8, 10]

mmm_audio_instance = MMMAudio(
    256 * 8, num_output_channels=2, graph_name="Sequencer", package_name="user"
)
mmm_audio_instance.start_audio()

mmm_audio_instance.send_float("change_tempo", 120)
mmm_audio_instance.send_floats("met.dur.change", [1, 0.125])
mmm_audio_instance.send_floats(
    "met.deltas.change", [0, 0, 0.5, 0.5, 0.5, 0.25, 0.25, 0.25, 0.25, 0, 0, 0, 1.0]
)

mmm_audio_instance.send_floats(
    "hi_hat.deltas.change", [0, 0, 0.25, 0.5, 0.25, 0.75, 0.25, 0.25, 0.25, 0.5]
)

mmm_audio_instance.send_floats("snare.amp.change", [0, 0.0, 0.125])
mmm_audio_instance.send_floats("kick.amp.change", [0, 0.5, 0.0])

mmm_audio_instance.send_floats("met_two.deltas.change", [1, 0.25, 0.25, 2])
mmm_audio_instance.send_floats("met.freq.change", [1, 77, 80, 82, 84, 87])

mmm_audio_instance.send_floats("met.freq.change", [72 + i for i in maj_pent])

hihat = Pbind(mmm_audio_instance, "hi_hat")
snare = Pbind(mmm_audio_instance, "snare")
kick = Pbind(mmm_audio_instance, "kick")

hihat.sched_n_bars(
    "deltas",
    1,
    Pattern.PSEQ,
    [
        1 / 4,
        1 / 4,
        1 / 4,
        1 / 4,
        1 / 8,
        1 / 8,
        1 / 4,
        1 / 4,
        1 / 4,
        1 / 4,
        1 / 4,
        1 / 4,
        1 / 4,
        1 / 4,
        1 / 4,
        1 / 8,
        1 / 8,
        1 / 4,
    ],
)

snare.sched_n_bars("amp", 1, Pattern.PSEQ, [0.0, 0.125])
kick.sched_n_bars("amp", 1, Pattern.PSEQ, [0.5])

pbind.sched_n_bars("freq", 1, 0, [67 + i for i in min_pent])

hihat.set_key("dur", 1, [0.05])
hihat.set_key("deltas", 1, [0.125, 0.25, 0.5, 1])

a = Pattern.PRAND
