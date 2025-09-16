# ffpresets.py
# Central map of encoders → preset values.
# Only includes encoders with a native "-preset" option.
# This is used to populate the VideoPreset QComboBox with presets conforming to the selected video codec.

# --- Shared dicts ---

# x264 / x265
X26X_PRESETS = {
    "values": [
        "ultrafast",
        "superfast",
        "veryfast",
        "faster",
        "fast",
        "medium",   # default
        "slow",
        "slower",
        "veryslow",
        "placebo",
    ],
    "default": "medium",
}

# NVENC (h264_nvenc / hevc_nvenc / av1_nvenc)
NVENC_PRESETS = {
    "values": ["p1", "p2", "p3", "p4", "p5", "p6", "p7"],
    # ffmpeg docs: p1 = slowest / best quality, p7 = fastest / lowest quality
    "default": "p4",
}

# Intel Quick Sync (qsv family)
QSV_PRESETS = {
    "values": [
        "veryfast",
        "faster",
        "fast",
        "medium",   # default
        "slow",
        "slower",
        "veryslow",
    ],
    "default": "medium",
}

# SVT-AV1
SVT_AV1_PRESETS = {
    "values": [str(i) for i in range(0, 14)],  # "0" .. "13"
    # 0 = best quality (slowest), 13 = fastest (lowest quality)
    "default": "8",  # upstream ffmpeg defaults to 8 if not specified
}

# --- Master map: encoder → preset spec ---
ENCODER_PRESETS = {
    # x264/265
    "libx264": X26X_PRESETS,
    "libx265": X26X_PRESETS,

    # NVENC
    "h264_nvenc": NVENC_PRESETS,
    "hevc_nvenc": NVENC_PRESETS,
    "av1_nvenc": NVENC_PRESETS,

    # QSV
    "h264_qsv": QSV_PRESETS,
    "hevc_qsv": QSV_PRESETS,
    "av1_qsv": QSV_PRESETS,

    # SVT-AV1
    "libsvtav1": SVT_AV1_PRESETS,
}


def get_presets_for(encoder: str):
    """
    Return a tuple (values, default, labels) for the given encoder.

    - values: list of preset strings (in UI order)
    - default: the default preset string
    - labels: dict mapping value -> friendly label (optional, may be empty)
    """
    spec = ENCODER_PRESETS.get(encoder)
    if not spec:
        return [], None, {}

    values = spec.get("values", [])
    default = spec.get("default")
    labels = spec.get("labels", {})

    return values, default, labels



























