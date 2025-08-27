#!/bin/bash
#
#
#
# To rebuild the FFmpeg commands database, run the following scripts:
# Run in this order:


echo "Removing current ffmpeg_options.db"
rm -f ffmpeg_options.db


# Creates initial database
# Tables created and populated: bitstream_filters, codecs, filters, muxers, pixel_formats
echo "Rebuilding initial database:"
python3 ffmpeg_db_builder.py --mode rebuild


# Add table encoders
echo "Adding encoders table:"
python3 populate_encoders.py

# Add table encoder_options
echo "Adding encoder_options:"
python3 populate_encoder_options.py

# Adds tables: muxers_info:
echo "Add muxers_info table:"
python3 populate_muxers_info.py

# Add muxer_options table
echo "Adding muxer_options table:"
python3 populate_muxer_options.py


# Adds tables: filter_options (no range or default columns)
echo "Adding Filters_options table:"
python3 populate_filter_options.py # Still messy

# Add table bitstream_filter_options
echo "Adding bitstream_filter_options table:"
python3 populate_bsf_options.py


echo ""
echo "All done!"
