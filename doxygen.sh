#!/usr/bin/env bash
if [ "$@" = "--version" ]; then
	echo "1.9.1"
	exit 0
fi

echo "doxygen stub: stubbing command $0 $@"

GENERATE_TEMPLATE=false
OUTPUT_FILE=""
CONFIG_FILE=""
READ_FROM_STDIN=false

while [[ $# -gt 0 ]]; do
	case $1 in
	-s)
		GENERATE_TEMPLATE=true
		shift
		;;
	-g)
		GENERATE_TEMPLATE=true
		shift
		if [[ $# -gt 0 && ! "$1" =~ ^- ]]; then
			OUTPUT_FILE="$1"
			shift
		fi
		;;
	--version)
		echo "1.9.1"
		exit 0
		;;
	-)
		READ_FROM_STDIN=true
		shift
		;;
	*)
		if [[ "$GENERATE_TEMPLATE" == "true" && -z "$OUTPUT_FILE" && ! "$1" =~ ^- ]]; then
			OUTPUT_FILE="$1"
		elif [[ -z "$CONFIG_FILE" && ! "$1" =~ ^- && -f "$1" ]]; then
			# This looks like a config file
			CONFIG_FILE="$1"
		else
			echo "Don't know how to handle arg $1, ignoring"
		fi
		shift
		;;
	esac
done

if [[ "$READ_FROM_STDIN" == "true" ]]; then
	CONFIG_FILE=$(mktemp)
	cat >"$CONFIG_FILE"
fi

# Generate minimal template if requested
if [[ "$GENERATE_TEMPLATE" == "true" && -n "$OUTPUT_FILE" ]]; then
	echo "Generating stubbed template $OUTPUT_FILE"
	cat >"$OUTPUT_FILE" <<'EOF'
PROJECT_NAME           = 
OUTPUT_DIRECTORY       = 
INPUT                  = 
RECURSIVE              = NO
GENERATE_HTML          = YES
GENERATE_LATEX         = YES
HAVE_DOT               = NO
DOT_MULTI_TARGETS      = NO
WARN_FORMAT            = $file:$line: $text
EXCLUDE_PATTERNS       = 
EOF
# Handle regular documentation generation
elif [[ -n "$CONFIG_FILE" && -f "$CONFIG_FILE" ]]; then
	cat $CONFIG_FILE
	# Extract OUTPUT_DIRECTORY, HTML_OUTPUT, and XML_OUTPUT from config file
	OUTPUT_DIR=$(grep "^OUTPUT_DIRECTORY" "$CONFIG_FILE" | cut -d'=' -f2 | tr -d ' ')
	HTML_OUTPUT=$(grep "^HTML_OUTPUT" "$CONFIG_FILE" | cut -d'=' -f2 | tr -d ' ')
	XML_OUTPUT=$(grep "^XML_OUTPUT" "$CONFIG_FILE" | cut -d'=' -f2 | tr -d ' ')

	OUTPUT_DIR=''${OUTPUT_DIR:-.}
	HTML_OUTPUT=''${HTML_OUTPUT:-html}
	XML_OUTPUT=''${XML_OUTPUT:-xml}

	# Handle absolute vs relative paths for XML_OUTPUT
	if [[ "$XML_OUTPUT" = /* ]]; then
		XML_OUTPUT="$XML_OUTPUT"
	else
		XML_OUTPUT="$OUTPUT_DIR/$XML_OUTPUT"
	fi
	if [[ "$HTML_OUTPUT" = /* ]]; then
		HTML_OUTPUT="$HTML_OUTPUT"
	else
		HTML_OUTPUT="$OUTPUT_DIR/$HTML_OUTPUT"
	fi

	# Create the expected directory structure
	mkdir -p "$HTML_OUTPUT" "$XML_OUTPUT"

	echo "Generating stubbed $HTML_OUTPUT/index.html"
	echo "<html><body><h1>Documentation generation disabled</h1></body></html>" >"$HTML_OUTPUT/index.html"

	# Generate empty files in html directory
	touch "$HTML_OUTPUT/style.css"
	touch "$HTML_OUTPUT/script.js"
	touch "$HTML_OUTPUT/logo.png"
	echo "Generating stubbed $XML_OUTPUT/index.xml"
	echo "<?xml version='1.0' encoding='UTF-8' standalone='no'?>
<doxygenindex xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"index.xsd\" version=\"1.9.1\" xml:lang=\"en-US\">
<compound refid=\"stub\" kind=\"group\">
    <name>stub</name>
    <title>Documentation generation disabled</title>
    <filename>stub</filename>
    <kind>none</kind>
</compound>
</doxygenindex>" >"$XML_OUTPUT/index.xml"
	echo "<?xml version='1.0' encoding='UTF-8' standalone='no'?><stub></stub>" >"$XML_OUTPUT/stub.xml"
	echo '<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="@*|node()">
    <xsl:copy>
    <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
</xsl:template>
</xsl:stylesheet>' >"$XML_OUTPUT/combine.xslt"

	# Extract INPUT files
	INPUT_FILES=$(grep "^INPUT" "$CONFIG_FILE" | cut -d'=' -f2 | tr -d ' ')

	# Generate XML files for each input file
	if [[ -n "$INPUT_FILES" ]]; then
		for input_file in $INPUT_FILES; do
			# Get just the filename without path
			basename_file=$(basename "$input_file")
			# Convert to doxygen XML filename format
			xml_filename=$(echo "$basename_file" | sed 's/\./_8/g').xml

			echo "Generating stubbed $XML_OUTPUT/$xml_filename"
			echo "<?xml version='1.0' encoding='UTF-8' standalone='no'?>
<doxygen xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"compound.xsd\" version=\"1.9.1\" xml:lang=\"en-US\">
<compounddef id=\"$xml_filename\" kind=\"file\" language=\"C++\" prot=\"public\">
    <compoundname>$basename_file</compoundname>
    <briefdescription>
    <para>Documentation generation disabled</para>
    </briefdescription>
    <detaileddescription>
    <para>This is a stub file. Documentation generation was disabled.</para>
    </detaileddescription>
</compounddef>
</doxygen>" >"$XML_OUTPUT/$xml_filename"
		done
	fi

	# Extract MAN_OUTPUT from config file
	MAN_OUTPUT=$(grep "^MAN_OUTPUT" "$CONFIG_FILE" | cut -d'=' -f2 | tr -d ' ')
	GENERATE_MAN=$(grep "^GENERATE_MAN" "$CONFIG_FILE" | cut -d'=' -f2 | tr -d ' ')
	# Generate man pages if enabled
	if [[ "$GENERATE_MAN" == "YES" ]]; then
		# Set default if not found
		MAN_OUTPUT=''${MAN_OUTPUT:-man}

		# Extract additional man-related variables
		PROJECT_NAME=$(grep "^PROJECT_NAME" "$CONFIG_FILE" | cut -d'=' -f2 | tr -d ' ' | tr -d '"')
		PROJECT_NUMBER=$(grep "^PROJECT_NUMBER" "$CONFIG_FILE" | cut -d'=' -f2 | tr -d ' ')
		MAN_EXTENSION=$(grep "^MAN_EXTENSION" "$CONFIG_FILE" | cut -d'=' -f2 | tr -d ' ')
		MAN_SUBDIR=$(grep "^MAN_SUBDIR" "$CONFIG_FILE" | cut -d'=' -f2 | tr -d ' ')

		# Set defaults and lowercase project name for filenames
		PROJECT_NAME=''${PROJECT_NAME:-"Project"}
		PROJECT_NAME_LOWER=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]')
		PROJECT_NUMBER=''${PROJECT_NUMBER:-"1.0"}
		MAN_EXTENSION=''${MAN_EXTENSION:-.3}
		MAN_SUBDIR=''${MAN_SUBDIR:-}

		# Create man page directories
		mkdir -p "$OUTPUT_DIR/$MAN_OUTPUT/man1"
		mkdir -p "$OUTPUT_DIR/$MAN_OUTPUT/man3"
		mkdir -p "$OUTPUT_DIR/$MAN_OUTPUT/man5"

		# man1 - typically for executables/commands
		echo ".TH $PROJECT_NAME 1 \"$(date)\" \"$PROJECT_NUMBER\" \"User Commands\"
.SH NAME
$PROJECT_NAME \- Documentation generation disabled
.SH DESCRIPTION
This is a stub man page. Documentation generation was disabled." >"$OUTPUT_DIR/$MAN_OUTPUT/man1/$PROJECT_NAME_LOWER.1"

		# man3 - typically for library functions/APIs
		echo ".TH $PROJECT_NAME 3 \"$(date)\" \"$PROJECT_NUMBER\" \"Library Functions\"
.SH NAME
$PROJECT_NAME \- Documentation generation disabled
.SH DESCRIPTION
This is a stub man page. Documentation generation was disabled." >"$OUTPUT_DIR/$MAN_OUTPUT/man3/$PROJECT_NAME_LOWER$MAN_EXTENSION"

		# man5 - typically for file formats/configuration files
		echo ".TH $PROJECT_NAME-FORMAT 5 \"$(date)\" \"$PROJECT_NUMBER\" \"File Formats\"
.SH NAME
$PROJECT_NAME-format \- Documentation generation disabled
.SH DESCRIPTION
This is a stub man page. Documentation generation was disabled." >"$OUTPUT_DIR/$MAN_OUTPUT/man5/$PROJECT_NAME_LOWER-format.5"
	fi
else
	echo "Not sure what to do, doing nothing"
fi
exit 0
