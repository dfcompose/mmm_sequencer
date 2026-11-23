from mmm_python import *


class Pbind:
    def __init__(self, instance, prefix="stream"):
        self.mmm_audio = instance
        self.prefix = prefix
        pass

    def sched_n_bars(self, key, bars, pattern, values):
        """
        Schedule a change in a key after n bars.

        Args:
            key: The key to be changed.
            bars: The number of bars before the change occurs.
            pattern: The pattern to use.
            values: The values for the pattern.
        """

        msg = []
        msg.append(bars)
        msg.append(pattern.value)
        if pattern.value == 0:
            msg.append(0)
        [msg.append(i) for i in values]
        self.mmm_audio.send_floats(f"{self.prefix}.{key}.next_bar", msg)

    def sched_n_beats(self, key, beats, pattern, values):
        """
        Schedule a change in a key after n beats.

        Args:
            key: The key to be changed.
            beats: The number of beats before the change occurs.
            pattern: The pattern to use.
            values: The values for the pattern.
        """
        msg = []
        msg.append(beats)
        msg.append(pattern.value)
        if pattern.value == 0:
            msg.append(0)
        [msg.append(i) for i in values]
        print(msg)
        self.mmm_audio.send_floats(f"{self.prefix}.{key}.next_beat", msg)

    def set_key(self, key, pattern, values):
        msg = []
        msg.append(pattern)
        [msg.append(i) for i in values]

        self.mmm_audio.send_floats(f"{self.prefix}.{key}.change", msg)


class Pattern(IntEnum):
    PSEQ = 0
    PRAND = 1
