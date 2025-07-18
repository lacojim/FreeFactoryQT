This is a sqlite3 database containing all the FFmpeg options. It is not yet being used by FreeFactory and is for future use. Initially it may be used to create queries to find compatible options.

In the future, it is hoped this can also be used to create a dynamic UI by only allowing to show compatible options in the (currently flat) QComboBoxes, etc for a given codec, muxer, etc.

Presently there are seven python scripts used to create this database. I will include those here at some point. Once they are more refined. They can be used to create a new database completely based on the version of the FFmpeg you have installed on your system.

As I am not normally a database administrator, I am sure there are many ways to make this much more efficient and much better. Database experts welcomed to offer improvments, please.


FFmpeg Database tools descriptions:

rebuild_database.sh: This will delete ffmpeg_options.db and run the following python scipts in the following order:

- ffmpeg_db_builder.py --mode rebuild
This will rebuild the database in a basic state and creates and populates the following tables: bitstream_filters, codecs, filters, muxers, pixel_formats

- populate_encoders.py
This parses, creates and populates the FFmpeg encoders/decoders table. 

- populate_encoder_options.py
This parses, creates and populates the FFmpeg encoder_options table. 

- populate_muxers_info.py
This parses, creates and populates the FFmpeg muxer_info table. 

- populate_muxer_options.py
This parses, creates and populates the FFmpeg muxer_options table. 

- populate_filter_options.py
This parses, creates and populates the FFmpeg filter_options table. 

- populate_bsf_options.py
This parses, creates and populates the FFmpeg bitstream_filter_options table. This takes several minutes to complete.

- populate_encoder_compat.py
This one is a beast on its own. It will actually run ffmpeg with generic options and according to your CPU core count can run many instances. It attempt to create compatible video+audio codec compatibility. It will use 100% off all your CPU cores and depending on your HW, can take from 15 minutes to several hours to complete. It is Not included in the rebuild_database.sh script because of this. You must run this one MANUALLY. 

- compatibility_overrides.json
This file is only used by the above script (populate_encoder_compat.py). If you already know what video codecs are compatible with whatever video codec, edit this file to skip the probe and it gets automatically added to the database table encoder_compatibility. This is because some codecs (ie dnxhd) only support 48khz audio streams and the test was originally written for 44.1k audio streams. Yea, it gets really complicated. Any combination of options for dnxhd for example, will fail if the audio is not 48khz. We are trying to prevent these types of misconfigurations but it gets complicated.



