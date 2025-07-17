This is a sqlite3 database containing all the FFmpeg options. It is not yet being used by FreeFactory and is for future use. Initially it may be used to create queries to find compatible options.

In the future, it is hoped this can also be used to create a dynamic UI by only allowing to show compatible options in the (currently flat) QComboBoxes, etc for a given codec, muxer, etc.

Presently there are seven python scripts used to create this database. I will include those here at some point. Once they are more refined. They can be used to create a new database completely based on the version of the FFmpeg you have installed on your system.

As I am not normally a database administrator, I am sure there are many ways to make this much more efficient and much better. Database experts welcome to offer improvments, please.
