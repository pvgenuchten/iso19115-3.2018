<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:cat="http://standards.iso.org/iso/19115/-3/cat/1.0"
                xmlns:cit="http://standards.iso.org/iso/19115/-3/cit/2.0"
                xmlns:gcx="http://standards.iso.org/iso/19115/-3/gcx/1.0"
                xmlns:gex="http://standards.iso.org/iso/19115/-3/gex/1.0"
                xmlns:lan="http://standards.iso.org/iso/19115/-3/lan/1.0"
                xmlns:srv="http://standards.iso.org/iso/19115/-3/srv/2.1"
                xmlns:mac="http://standards.iso.org/iso/19115/-3/mac/2.0"
                xmlns:mas="http://standards.iso.org/iso/19115/-3/mas/1.0"
                xmlns:mcc="http://standards.iso.org/iso/19115/-3/mcc/1.0"
                xmlns:mco="http://standards.iso.org/iso/19115/-3/mco/1.0"
                xmlns:mda="http://standards.iso.org/iso/19115/-3/mda/1.0"
                xmlns:mdb="http://standards.iso.org/iso/19115/-3/mdb/2.0"
                xmlns:mdt="http://standards.iso.org/iso/19115/-3/mdt/2.0"
                xmlns:mex="http://standards.iso.org/iso/19115/-3/mex/1.0"
                xmlns:mic="http://standards.iso.org/iso/19115/-3/mic/1.0"
                xmlns:mil="http://standards.iso.org/iso/19115/-3/mil/1.0"
                xmlns:mrl="http://standards.iso.org/iso/19115/-3/mrl/2.0"
                xmlns:mds="http://standards.iso.org/iso/19115/-3/mds/2.0"
                xmlns:mmi="http://standards.iso.org/iso/19115/-3/mmi/1.0"
                xmlns:mpc="http://standards.iso.org/iso/19115/-3/mpc/1.0"
                xmlns:mrc="http://standards.iso.org/iso/19115/-3/mrc/2.0"
                xmlns:mrd="http://standards.iso.org/iso/19115/-3/mrd/1.0"
                xmlns:mri="http://standards.iso.org/iso/19115/-3/mri/1.0"
                xmlns:mrs="http://standards.iso.org/iso/19115/-3/mrs/1.0"
                xmlns:msr="http://standards.iso.org/iso/19115/-3/msr/2.0"
                xmlns:mai="http://standards.iso.org/iso/19115/-3/mai/1.0"
                xmlns:mdq="http://standards.iso.org/iso/19157/-2/mdq/1.0"
                xmlns:gco="http://standards.iso.org/iso/19115/-3/gco/1.0"
                xmlns:gml="http://www.opengis.net/gml/3.2"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:datacite="http://datacite.org/schema/kernel-4"
                xmlns:tr="java:org.fao.geonet.api.records.formatters.SchemaLocalizations"
                xmlns:saxon="http://saxon.sf.net/"
                xmlns:gn="http://www.fao.org/geonetwork"
                xmlns:gn-fn-index="http://geonetwork-opensource.org/xsl/functions/index"
                xmlns:schema-org-fn="http://geonetwork-opensource.org/xsl/functions/schema-org"
                xmlns:util="java:org.fao.geonet.util.XslUtil"
                version="2.0"
                extension-element-prefixes="saxon"
                exclude-result-prefixes="#all">

  <!-- Used for json escape string -->
  <xsl:import href="common/index-utils.xsl"/>

  <!-- Convert a hierarchy level into corresponding
  schema.org class. If no match, return http://schema.org/Thing

  Prefix are usually 'http://schema.org/' or 'schema:'.
   -->
  <xsl:function name="schema-org-fn:getType" as="xs:string">
    <xsl:param name="type" as="xs:string"/>
    <xsl:param name="prefix" as="xs:string"/>

    <xsl:variable name="map" as="node()+">
      <entry key="dataset" value="Dataset"/>
      <entry key="series" value="Dataset"/>
      <entry key="service" value="WebAPI"/>
      <entry key="application" value="SoftwareApplication"/>
      <entry key="collectionHardware" value="Thing"/>
      <entry key="nonGeographicDataset" value="Dataset"/>
      <entry key="dimensionGroup" value="TechArticle"/>
      <entry key="featureType" value="Dataset"/>
      <entry key="model" value="TechArticle"/>
      <entry key="tile" value="Dataset"/>
      <entry key="fieldSession" value="Project"/>
      <entry key="collectionSession" value="Project"/>
    </xsl:variable>

    <xsl:variable name="match"
                  select="$map[@key = $type]/@value"/>

    <xsl:variable name="prefixedBy"
                  select="if ($prefix = '') then 'http://schema.org/' else $prefix"/>

    <xsl:value-of select="if ($match != '')
                          then concat($prefixedBy, $match)
                          else concat($prefixedBy, 'Thing')"/>
  </xsl:function>


  <!-- Define the root element of the resources
      and a catalogue id. -->
  <!--<xsl:param name="baseUrl"
             select="'https://data.geocatalogue.fr/id/'"/>
     <xsl:variable name="catalogueName"
             select="'/geocatalogue'"/>
  -->
  <xsl:param name="baseUrl"
             select="util:getSettingValue('nodeUrl')"/>
  <xsl:variable name="catalogueName"
                select="''"/>

  <!-- Schema.org document can't really contain
  translated text. So we can produce the JSON-LD
  in one of the language defined in the metadata record.

  Add the lang parameter to the formatter URL `?lang=fr`
  to force a specific language. If translation not available,
  the default record language is used.
  -->
  <xsl:param name="lang"
             select="''"/>


  <!-- TODO: Convert language code eng > en_US ? -->
  <xsl:variable name="defaultLanguage"
                select="//mdb:MD_Metadata/mdb:defaultLocale/*/lan:language/*/@codeListValue"/>

  <xsl:variable name="requestedLanguageExist"
                select="$lang != ''
                        and count(//mdb:MD_Metadata/mdb:locale/*[mdb:languageCode/*/@codeListValue = $lang]/@id) > 0"/>

  <xsl:variable name="requestedLanguage"
                select="if ($requestedLanguageExist)
                        then $lang
                        else //mdb:MD_Metadata/mdb:defaultLocale/*/lan:language/*/@codeListValue"/>

  <xsl:variable name="requestedLanguageId"
                select="concat('#', //mdb:MD_Metadata/mdb:locale/*[mdb:languageCode/*/@codeListValue = $requestedLanguage]/@id)"/>



  <xsl:template name="getJsonLD"
                mode="getJsonLD" match="mdb:MD_Metadata">

	{
		"@context": "http://schema.org/",
    <xsl:choose>
      <xsl:when test="mdb:metadataScope/*/mdb:resourceScope/*/@codeListValue != ''">
		    "@type": "<xsl:value-of select="schema-org-fn:getType(mdb:metadataScope/*/mdb:resourceScope/*/@codeListValue, 'schema:')"/>",
      </xsl:when>
      <xsl:otherwise>
        "@type": "schema:Dataset",
      </xsl:otherwise>
    </xsl:choose>
    <!-- TODO: Use the identifier property to attach any relevant Digital Object identifiers (DOIs). -->
		"@id": "<xsl:value-of select="concat($baseUrl, 'api/records/', mdb:MD_Metadata/mdb:metadataIdentifier/*/mcc:code/*/text())"/>",
		"includedInDataCatalog":["<xsl:value-of select="concat($baseUrl, 'search#', $catalogueName)"/>"],
    <!-- TODO: is the dataset language or the metadata language ? -->
    "inLanguage":"<xsl:value-of select="$requestedLanguage"/>",
    <!-- TODO: availableLanguage -->
    "name": "<xsl:value-of
                                 select="mdb:MD_Metadata/mdb:identificationInfo/*/mri:citation/*/cit:title"/>",

    <!-- An alias for the item. -->
    <xsl:for-each select="mdb:identificationInfo/*/mdb:citation/*/mdb:alternateTitle">
      "alternateName": "<xsl:value-of
                                                  select="./*/text()"/>",
    </xsl:for-each>

    <xsl:for-each select="mdb:identificationInfo/*/mdb:citation/*/mdb:date[mdb:dateType/*/@codeListValue='creation']/*/mdb:date/*/text()">
		  "dateCreated": "<xsl:value-of select="."/>",
    </xsl:for-each>
    <xsl:for-each select="mdb:identificationInfo/*/mdb:citation/*/mdb:date[mdb:dateType/*/@codeListValue='revision']/*/mdb:date/*/text()">
		"dateModified": "<xsl:value-of select="."/>",
    </xsl:for-each>
    <xsl:for-each select="mdb:identificationInfo/*/mdb:graphicOverview/*/mdb:fileName/*[. != '']">
		"thumbnailUrl": "<xsl:value-of select="."/>",
    </xsl:for-each>

		"description": "<xsl:value-of select="mdb:identificationInfo/*/mdb:abstract/*/text()"/>",

    <!-- TODO: Add citation as defined in DOI landing pages -->
    <!-- TODO: Add identifier, DOI if available or URL or text -->

    <xsl:for-each select="mdb:identificationInfo/*/mdb:citation/*/mdb:edition/gco:CharacterString[. != '']">
      "version": "<xsl:value-of select="."/>",
    </xsl:for-each>


    <!-- Build a flat list of all keywords even if grouped in thesaurus. -->
    "keywords":[
      <xsl:for-each select="mdb:identificationInfo/*/mdb:descriptiveKeywords/mdb:MD_Keywords/mdb:keyword">
        <xsl:apply-templates mode="toJsonLDLocalized"
                             select=".">
          <xsl:with-param name="asArray" select="false()"/>
        </xsl:apply-templates>
        <xsl:if test="position() != last()">,</xsl:if>
      </xsl:for-each>
		],


    <!--
    TODO: Dispatch in author, contributor, copyrightHolder, editor, funder,
    producer, provider, sponsor
    TODO: sourceOrganization
      <xsl:variable name="role" select="*/mdb:role/mdb:CI_RoleCode/@codeListValue" />
      <xsl:choose>
        <xsl:when test="$role='resourceProvider'">provider</xsl:when>
        <xsl:when test="$role='custodian'">provider</xsl:when>
        <xsl:when test="$role='owner'">copyrightHolder</xsl:when>
        <xsl:when test="$role='user'">user</xsl:when>
        <xsl:when test="$role='distributor'">publisher</xsl:when>
        <xsl:when test="$role='originator'">sourceOrganization</xsl:when>
        <xsl:when test="$role='pointOfContact'">provider</xsl:when>
        <xsl:when test="$role='principalInvestigator'">producer</xsl:when>
        <xsl:when test="$role='processor'">provider</xsl:when>
        <xsl:when test="$role='publisher'">publisher</xsl:when>
        <xsl:when test="$role='author'">author</xsl:when>
        <xsl:otherwise>provider</xsl:otherwise>
      </xsl:choose>

    -->
    "publisher": [
      <xsl:for-each select="mdb:identificationInfo/*/mdb:pointOfContact/*">
        {
        <!-- TODO: Id could also be website if set -->
        <xsl:variable name="id"
                      select="mdb:contactInfo/*/mdb:address/*/mdb:electronicMailAddress/*/text()[1]"/>
        "@id":"<xsl:value-of select="$id"/>",
        "@type":"Organization"
        <xsl:for-each select="mdb:organisationName">
          ,"name": <xsl:apply-templates mode="toJsonLDLocalized"
                                       select="."/>
        </xsl:for-each>
        <xsl:for-each select="mdb:contactInfo/*/mdb:address/*/mdb:electronicMailAddress">
          ,"email": <xsl:apply-templates mode="toJsonLDLocalized"
                                       select="."/>
        </xsl:for-each>

        <!-- TODO: only if children available -->
        ,"contactPoint": {
          "@type" : "PostalAddress"
          <xsl:for-each select="mdb:contactInfo/*/mdb:address/*/mdb:country">
            ,"addressCountry": <xsl:apply-templates mode="toJsonLDLocalized"
                                                   select="."/>
          </xsl:for-each>
          <xsl:for-each select="mdb:contactInfo/*/mdb:address/*/mdb:city">
            ,"addressLocality": <xsl:apply-templates mode="toJsonLDLocalized"
                                                   select="."/>
          </xsl:for-each>
          <xsl:for-each select="mdb:contactInfo/*/mdb:address/*/mdb:postalCode">
            ,"postalCode": <xsl:apply-templates mode="toJsonLDLocalized"
                                                   select="."/>
          </xsl:for-each>
          <xsl:for-each select="mdb:contactInfo/*/mdb:address/*/mdb:deliveryPoint">
            ,"streetAddress": <xsl:apply-templates mode="toJsonLDLocalized"
                                                   select="."/>
          </xsl:for-each>
          }
        }
        <xsl:if test="position() != last()">,</xsl:if>
      </xsl:for-each>
    ]

    <xsl:for-each select="mdb:identificationInfo/*/mdb:citation/*/mdb:date[mdb:dateType/*/@codeListValue='publication']/*/mdb:date/*/text()">
      ,"datePublished": "<xsl:value-of select="."/>"
    </xsl:for-each>


    <!--
    The overall rating, based on a collection of reviews or ratings, of the item.
    "aggregateRating": TODO
    -->

    <!--
    A downloadable form of this dataset, at a specific location, in a specific format.

    See https://schema.org/DataDownload
    -->
    <xsl:for-each select="mdb:distributionInfo">
    ,"distribution": [
      <xsl:for-each select=".//mdb:onLine/*[mdb:linkage/mdb:URL != '']">
        {
        "@type":"DataDownload",
        "contentUrl":"<xsl:value-of select="mdb:linkage/mdb:URL/text()"/>",
        "encodingFormat":"<xsl:value-of select="mdb:protocol/*/text()"/>",
        "name":"<xsl:value-of select="mdb:name/*/text()"/>",
        "description":"<xsl:value-of select="mdb:description/*/text()"/>"
        }
        <xsl:if test="position() != last()">,</xsl:if>
      </xsl:for-each>
    ]
    </xsl:for-each>

    <xsl:if test="count(mdb:distributionInfo/*/mdb:distributionFormat) > 0">
      ,"encodingFormat": [
      <xsl:for-each select="mdb:distributionInfo/*/mdb:distributionFormat/*/mdb:name[. != '']">
        <xsl:apply-templates mode="toJsonLDLocalized"
                             select="."/>
        <xsl:if test="position() != last()">,</xsl:if>
      </xsl:for-each>
      ]
    </xsl:if>



    <xsl:for-each select="mdb:identificationInfo/*/mdb:extent/*[mdb:geographicElement]">
    ,"spatialCoverage": {
      "@type":"Place"
      <xsl:for-each select="mdb:description[count(.//text() != '') > 0]">
      ,"description": <xsl:apply-templates mode="toJsonLDLocalized"
                                           select="."/>
      </xsl:for-each>


      <xsl:for-each select="mdb:geographicElement/mdb:EX_GeographicBoundingBox">
        ,"geo": {
          "@type":"GeoShape",
          "box": "<xsl:value-of select="string-join((
                                          mdb:southBoundLatitude/gco:Decimal|
                                          mdb:westBoundLongitude/gco:Decimal|
                                          mdb:northBoundLatitude/gco:Decimal|
                                          mdb:eastBoundLongitude/gco:Decimal
                                          ), ' ')"/>"
        }
      </xsl:for-each>
    }
    </xsl:for-each>


    <xsl:for-each select="mdb:identificationInfo/*/mdb:extent/*/mdb:temporalElement/*/mdb:extent">
      ,"temporalCoverage": "<xsl:value-of select="concat(
                                                  gml:TimePeriod/gml:beginPosition, '/',
                                                  gml:TimePeriod/gml:endPosition
      )"/>"
      <!-- TODO: handle
      "temporalCoverage" : "2013-12-19/.."
      "temporalCoverage" : "2008"
      -->
    </xsl:for-each>

    <xsl:for-each select="mdb:identificationInfo/*/mdb:resourceConstraints/mdb:MD_LegalConstraints/mdb:otherConstraints">
      ,"license": <xsl:apply-templates mode="toJsonLDLocalized"
                                      select="."/>
    </xsl:for-each>

    <!-- TODO: When a dataset derives from or aggregates several originals, use the isBasedOn property. -->
    <!-- TODO: hasPart -->
	}
	</xsl:template>






  <xsl:template name="toJsonLDLocalized"
                mode="toJsonLDLocalized" match="*">
    <xsl:param name="asArray"
               select="true()"/>

    <xsl:choose>
      <!--
      This https://json-ld.org/spec/latest/json-ld/#string-internationalization
      should be supported in JSON-LD for multilingual content but does not
      seems to be supported yet by https://search.google.com/structured-data/testing-tool

      Error is not a valid type for property.

      So for now, JSON-LD format will only provide one language.
      The main one or the requested and if not found, the default.

      <xsl:when test="mdb:PT_FreeText">
        &lt;!&ndash; An array of object with all translations &ndash;&gt;
        <xsl:if test="$asArray">[</xsl:if>
        <xsl:for-each select="mdb:PT_FreeText/mdb:textGroup">
          <xsl:variable name="languageId"
                        select="mdb:LocalisedCharacterString/@locale"/>
          <xsl:variable name="languageCode"
                        select="$metadata/mdb:locale/*[concat('#', @id) = $languageId]/mdb:languageCode/*/@codeListValue"/>
          {
          <xsl:value-of select="concat('&quot;@value&quot;: &quot;',
                              gn-fn-index:json-escape(mdb:LocalisedCharacterString/text()),
                              '&quot;')"/>,
          <xsl:value-of select="concat('&quot;@language&quot;: &quot;',
                              $languageCode,
                              '&quot;')"/>
          }
          <xsl:if test="position() != last()">,</xsl:if>
        </xsl:for-each>
        <xsl:if test="$asArray">]</xsl:if>
        &lt;!&ndash;<xsl:if test="position() != last()">,</xsl:if>&ndash;&gt;
      </xsl:when>-->
      <xsl:when test="$requestedLanguage != ''">
        <xsl:variable name="requestedValue"
                      select="mdb:PT_FreeText/*/mdb:LocalisedCharacterString[@id = $requestedLanguageId]/text()"/>
        <xsl:value-of select="concat('&quot;',
                              gn-fn-index:json-escape(
                                if ($requestedValue != '') then $requestedValue else (gco:CharacterString)),
                              '&quot;')"/>
      </xsl:when>
      <xsl:otherwise>
        <!-- A simple property value -->
        <xsl:value-of select="concat('&quot;',
                              gn-fn-index:json-escape(gco:CharacterString),
                              '&quot;')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
