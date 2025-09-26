# ffprofiles.py
# Central map of encoders → preset values.
# Only includes encoders with a native "-preset" option.
# This is used to populate the VideoPreset QComboBox with presets conforming to the selected video codec.
# To-Add mpeg2_qsv, vp9_qsv

# --- Shared dicts ---

# DNxHD PROFILES
DNXHD_PROFILES = {
    "values": [
        "dnxhr_lb",
        "dnxhr_sq",
        "dnxhr_hq",
        "dnxhr_hqx",
        "dnxhr_444",
    ],
    "default": "dnxhr_sq",
}

# PRORES PROFILES
PRORES_PROFILES = {
    "values": [
        "proxy",
        "lt",
        "standard",
        "hq",
        "4444",
        "4444xq",
    ],
    "default": "standard"
}

# AV1 VAAPI PROFILES 
AV1_VAAPI_PROFILES = {
    "values": ["main", "high", "professional",],
    "default": "main",
}


# H264_NVENC PROFILES 
H264_NVENC_PROFILES = {
    "values": ["baseline", "main", "high", "high444p",],
    "default": "main",
}

# H265 HEVC_NVENC PROFILES 
HEVC_NVENC_PROFILES = {
    "values": ["main", "main10", "rext",],
    "default": "main",
}

# H.264 (software) profiles via libx264
H264_X264_PROFILES = {
    "values": ["baseline", "main", "high", "high10", "high422", "high444"],
    "default": "high",
}

# H.265 / HEVC (software) profiles via libx265
# Note: availability depends on the libx265 build; keep the portable ones.
HEVC_X265_PROFILES = {
    "values": ["main", "main10", "mainstillpicture"],
    "default": "main",
}

# MPEG2 profiles via mpeg2video
MPEG2_PROFILES = {
    "values": ["simple", "main", "high",],
    "default": "high",
}

# VP9 profiles
VP9_PROFILES = {
    "values": ["profile0", "profile1", "profile2", "profile3",],
    "default": "high",
}




# --- Master map: encoder → preset spec ---
ENCODER_PROFILES = {
    # HW x264/x265
    "h264_nvenc": H264_NVENC_PROFILES,
    "hevc_nvenc": HEVC_NVENC_PROFILES,
    
    # Software libx264/libx265
    "libx264": H264_X264_PROFILES,
    "libx265": HEVC_X265_PROFILES,

    # DNXHD 
    "dnxhd": DNXHD_PROFILES,
    
    # PRORES PROFILES
    "prores_ks": PRORES_PROFILES,

    # AV1_VAAPI
    "libsvtav1": AV1_VAAPI_PROFILES,
    
    # MPEG2
    "mpeg2video": MPEG2_PROFILES,
    
    # VP9
    "vp9": VP9_PROFILES,
}


def get_profiles_for(encoder: str):
    """
    Return a tuple (values, default, labels) for the given encoder.

    - values: list of preset strings (in UI order)
    - default: the default preset string
    - labels: dict mapping value -> friendly label (optional, may be empty)
    """
    spec = ENCODER_PROFILES.get(encoder)
    if not spec:
        return [], None, {}

    values = spec.get("values", [])
    default = spec.get("default")
    labels = spec.get("labels", {})

    return values, default, labels


