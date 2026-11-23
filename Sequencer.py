from mmm_python import *
from user.Pbind import *

mmm_audio_instance = MMMAudio(
    256 * 8, num_output_channels=2, graph_name="Sequencer", package_name="user"
)
mmm_audio_instance.start_audio()

mmm_audio_instance.send_float("change_tempo", 120)

hihat = Pbind(mmm_audio_instance, "hi_hat")
snare = Pbind(mmm_audio_instance, "snare")
kick = Pbind(mmm_audio_instance, "kick")

hihat.sched_n_bars(
    "deltas",
    1,
    Pattern.PSEQ,
    [1 / 4, 1 / 4, 1 / 4, 1 / 8, 1 / 8],
)

snare.sched_n_bars("amp", 1, Pattern.PSEQ, [0.0, 0.125])
kick.sched_n_bars("amp", 1, Pattern.PSEQ, [0.5, 0.0])
