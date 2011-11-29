To create the translation of other schema files:


FROM=de
TO=en
PUBLISHER_ROOT=/path/to/the/directory/with/lib/and/schema
java -jar $PUBLISHER_ROOT/lib/saxon9he.jar -s:$PUBLISHER_ROOT/schema/layoutschema-$FROM.rng -o:$PUBLISHER_ROOT/schema/$TO.rng -xsl:$PUBLISHER_ROOT/schema/translate_schema.xsl pTo=$TO
