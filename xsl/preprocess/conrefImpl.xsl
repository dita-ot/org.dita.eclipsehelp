<?xml version="1.0" encoding="utf-8"?>
<!--
This file is part of the DITA Open Toolkit project.

Copyright 2004, 2005 IBM Corporation

See the accompanying LICENSE file for applicable license.
-->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:conref="http://dita-ot.sourceforge.net/ns/200704/conref"
  xmlns:ditamsg="http://dita-ot.sourceforge.net/ns/200704/ditamsg" xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:dita-ot="http://dita-ot.sourceforge.net/ns/201007/dita-ot" exclude-result-prefixes="ditamsg conref xs dita-ot">

  <xsl:template match="*[@conref][@conref != ''][not(@conaction)]" priority="10">
    <!-- If we have already followed a relative path, pick it up -->
    <xsl:param name="current-relative-path" tunnel="yes" as="xs:string" select="''"/>
    <xsl:param name="conref-source-topicid" tunnel="yes" as="xs:string?"/>
    <xsl:param name="source-attributes" as="xs:string*"/>
    <xsl:param name="conref-ids" tunnel="yes" as="xs:string*"/>
    <xsl:param name="WORKDIR" tunnel="yes" as="xs:string">
      <xsl:apply-templates select="/processing-instruction('workdir-uri')[1]" mode="get-work-dir"/>
    </xsl:param>
    <xsl:param name="original-element" as="xs:string">
      <xsl:call-template name="get-original-element"/>
    </xsl:param>
    <xsl:param name="original-attributes" select="@*" as="attribute()*"/>

    <xsl:variable name="conrefend" as="xs:string?">
      <xsl:choose>
        <xsl:when test="dita-ot:has-element-id(@conrefend)">
          <xsl:value-of select="dita-ot:get-element-id(@conrefend)"/>
        </xsl:when>
        <xsl:when test="contains(@conrefend, '#')">
          <xsl:value-of select="substring-after(@conrefend, '#')"/>
        </xsl:when>
        <xsl:when test="contains(@conrefend, '/')">
          <xsl:value-of select="substring-after(@conrefend, '/')"/>
        </xsl:when>
        <xsl:when test="exists(@conrefend)">
          <xsl:value-of select="@conrefend"/>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="add-relative-path" as="xs:string">
      <xsl:call-template name="find-relative-path"/>
    </xsl:variable>
    <!-- Add this to the list of followed conref IDs -->
    <xsl:variable name="updated-conref-ids" select="($conref-ids, generate-id(.))"/>

    <!-- Keep the source node in a variable, to pass to the target. It can be used to save 
       attributes that were specified locally. If for some reason somebody passes from
       conref straight to conref, then just save the first one (in source-attributes) -->

    <!--get element local name, parent topic's domains, and then file name, topic id, element id from conref value-->
    <xsl:variable name="element" select="local-name(.)"/>
    <!--xsl:variable name="domains"><xsl:value-of select="ancestor-or-self::*[@domains][1]/@domains"/></xsl:variable-->

    <xsl:variable name="file-prefix" select="concat($WORKDIR, $current-relative-path)" as="xs:string"/>

    <xsl:variable name="file-origin" as="xs:string">
      <xsl:call-template name="get-file-uri">
        <xsl:with-param name="href" select="@conref"/>
        <xsl:with-param name="file-prefix" select="$file-prefix"/>
      </xsl:call-template>
    </xsl:variable>

    <xsl:variable name="file" as="xs:string">
      <xsl:call-template name="replace-blank">
        <xsl:with-param name="file-origin">
          <xsl:value-of select="$file-origin"/>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:variable>
    <!-- get domains attribute in the target file -->
    <xsl:variable name="domains"
      select="(document($file, /)/*/@domains | document($file, /)/dita/*[@domains][1]/@domains)[1]" as="xs:string?"/>
    <!--the file name is useful to href when resolving conref -->
    <xsl:variable name="conref-filename" as="xs:string">
      <xsl:call-template name="replace-blank">
        <xsl:with-param name="file-origin"
          select="substring-after(substring-after($file-origin, $file-prefix), $add-relative-path)"/>
      </xsl:call-template>
    </xsl:variable>

    <xsl:variable name="conref-source-topic" as="xs:string">
      <xsl:choose>
        <xsl:when test="normalize-space($conref-source-topicid)">
          <xsl:value-of select="$conref-source-topicid"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="ancestor-or-self::*[contains(@class, ' topic/topic ')][1]/@id"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- conref file name with relative path -->
    <xsl:variable name="filename" select="substring-after($file-origin, $file-prefix)"/>

    <!-- replace the extension name -->
    <xsl:variable name="FILENAME" select="concat(substring-before($filename, '.'), '.dita')"/>

    <xsl:variable name="topicid" select="dita-ot:get-topic-id(@conref)" as="xs:string?"/>
    <xsl:variable name="elemid" select="dita-ot:get-element-id(@conref)" as="xs:string?"/>
    <xsl:variable name="lastClassToken" select="concat(' ', tokenize(normalize-space(@class), ' ')[last()], ' ')"
      as="xs:string"/>

    <xsl:choose>
      <!-- exportanchors defined in topicmeta-->
      <xsl:when
        test="
          ($TRANSTYPE = 'eclipsehelp')
          and (document($EXPORTFILE, /)//file[@name = $FILENAME]/id[@name = $elemid])
          and (document($EXPORTFILE, /)//file[@name = $FILENAME]/topicid[@name = $topicid])">
        <!-- just copy -->
        <xsl:copy>
          <xsl:apply-templates select="@* | node()">
            <xsl:with-param name="current-relative-path" tunnel="yes" select="$current-relative-path"/>
            <xsl:with-param name="conref-filename" tunnel="yes" select="$conref-filename"/>
            <xsl:with-param name="WORKDIR" tunnel="yes" select="$WORKDIR"/>
          </xsl:apply-templates>
        </xsl:copy>
      </xsl:when>
      <!-- exportanchors defined in prolog-->
      <xsl:when
        test="
          ($TRANSTYPE = 'eclipsehelp')
          and document($EXPORTFILE, /)//file[@name = $FILENAME]/topicid[@name = $topicid]/id[@name = $elemid]">
        <!-- just copy -->
        <xsl:copy>
          <xsl:apply-templates select="@* | node()">
            <xsl:with-param name="current-relative-path" tunnel="yes" select="$current-relative-path"/>
            <xsl:with-param name="conref-filename" tunnel="yes" select="$conref-filename"/>
            <xsl:with-param name="WORKDIR" tunnel="yes" select="$WORKDIR"/>
          </xsl:apply-templates>
        </xsl:copy>
      </xsl:when>
      <!-- just has topic id -->
      <xsl:when
        test="
          empty($elemid) and ($TRANSTYPE = 'eclipsehelp')
          and (document($EXPORTFILE, /)//file[@name = $FILENAME]/topicid[@name = $topicid]
          or document($EXPORTFILE, /)//file[@name = $FILENAME]/topicid[@name = $topicid]/id[@name = $elemid])">
        <!-- just copy -->
        <xsl:copy>
          <xsl:apply-templates select="@* | node()">
            <xsl:with-param name="current-relative-path" tunnel="yes" select="$current-relative-path"/>
            <xsl:with-param name="conref-filename" tunnel="yes" select="$conref-filename"/>
            <xsl:with-param name="WORKDIR" tunnel="yes" select="$WORKDIR"/>
          </xsl:apply-templates>
        </xsl:copy>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="current-element" select="."/>
        <!-- do as usual -->
        <xsl:variable name="topicpos" as="xs:string">
          <xsl:choose>
            <xsl:when test="starts-with(@conref, '#')">samefile</xsl:when>
            <xsl:when test="contains(@conref, '#')">otherfile</xsl:when>
            <xsl:otherwise>firstinfile</xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:choose>
          <xsl:when test="$conref-ids = generate-id(.)">
            <xsl:apply-templates select="." mode="ditamsg:conrefLoop"/>
          </xsl:when>
          <xsl:when
            test="
              exists($elemid)
              or contains(@class, ' topic/topic ')
              or contains(@class, ' map/topicref ')
              or contains(/*/@class, ' map/map ')
              or substring-after(@conref, '#') != ''">
            <xsl:variable name="target-doc" as="document-node()?">
              <xsl:choose>
                <xsl:when test="$topicpos = 'samefile'">
                  <xsl:sequence select="root(.)"/>
                </xsl:when>
                <xsl:when test="$topicpos = ('otherfile', 'firstinfile')">
                  <xsl:sequence
                    select="
                      if (doc-available(resolve-uri($file, base-uri(/)))) then
                        document($file, /)
                      else
                        ()"
                  />
                </xsl:when>
              </xsl:choose>
            </xsl:variable>
            <xsl:choose>
              <xsl:when test="empty($target-doc)">
                <xsl:apply-templates select="$current-element" mode="ditamsg:missing-conref-target-error"/>
              </xsl:when>
              <xsl:when test="conref:isValid($domains, false())">
                <xsl:if test="not(conref:isValid($domains, true()))">
                  <xsl:apply-templates select="." mode="ditamsg:weakConstraintMismatch"/>
                </xsl:if>
                <xsl:for-each select="$target-doc">
                  <xsl:variable name="target" as="element()*">
                    <xsl:choose>
                      <xsl:when test="exists($elemid)">
                        <xsl:sequence
                          select="key('id', $elemid)[contains(@class, $lastClassToken)][ancestor::*[contains(@class, ' topic/topic ')][1][@id = $topicid]]"
                        />
                      </xsl:when>
                      <xsl:when test="exists($topicid) and contains($current-element/@class, ' topic/topic ')">
                        <xsl:sequence
                          select="key('id', $topicid)[contains(@class, ' topic/topic ')][contains(@class, $lastClassToken)]"
                        />
                      </xsl:when>
                      <xsl:when test="exists($topicid) and contains($current-element/@class, ' map/topicref ')">
                        <xsl:sequence
                          select="key('id', $topicid)[contains(@class, ' map/topicref ')][contains(@class, $lastClassToken)]"
                        />
                      </xsl:when>
                      <xsl:when test="exists($topicid) and contains(root($current-element)/*/@class, ' map/map ')">
                        <xsl:sequence select="key('id', $topicid)[contains(@class, $lastClassToken)]"/>
                      </xsl:when>
                      <xsl:when test="exists($topicid)">
                        <xsl:sequence select="key('id', $topicid)[contains(@class, $lastClassToken)]"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:sequence
                          select="//*[contains(@class, ' topic/topic ')][1][contains(@class, $lastClassToken)]"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  <xsl:choose>
                    <xsl:when test="$target">
                      <xsl:variable name="firstTopicId"
                        select="
                          if (exists($topicid)) then
                            $topicid
                          else
                            $target/@id"/>
                      <xsl:choose>
                        <!-- if the first topic id is exported and transtype is eclipsehelp-->
                        <!-- XXX it would be good if this could be move higher up -->
                        <xsl:when
                          test="
                            $TRANSTYPE = 'eclipsehelp'
                            and empty($topicid) and empty($elemid)
                            and document($EXPORTFILE, $current-element)//file[@name = $FILENAME]/topicid[@name = $firstTopicId]">
                          <xsl:copy>
                            <xsl:apply-templates select="node()">
                              <xsl:with-param name="current-relative-path" tunnel="yes" select="$current-relative-path"/>
                              <xsl:with-param name="conref-filename" tunnel="yes" select="$conref-filename"/>
                              <xsl:with-param name="WORKDIR" tunnel="yes" select="$WORKDIR"/>
                            </xsl:apply-templates>
                          </xsl:copy>
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:apply-templates select="$target[1]" mode="conref-target">
                            <xsl:with-param name="source-attributes" as="xs:string*">
                              <xsl:choose>
                                <xsl:when test="exists($source-attributes)">
                                  <xsl:sequence select="$source-attributes"/>
                                </xsl:when>
                                <xsl:otherwise>
                                  <xsl:call-template name="get-source-attribute">
                                    <xsl:with-param name="current-node" select="$current-element"/>
                                  </xsl:call-template>
                                </xsl:otherwise>
                              </xsl:choose>
                            </xsl:with-param>
                            <xsl:with-param name="current-relative-path" tunnel="yes"
                              select="concat($current-relative-path, $add-relative-path)"/>
                            <xsl:with-param name="WORKDIR" tunnel="yes" select="$WORKDIR"/>
                            <xsl:with-param name="conref-filename" tunnel="yes" select="$conref-filename"/>
                            <xsl:with-param name="conref-source-topicid" tunnel="yes" select="$conref-source-topic"/>
                            <xsl:with-param name="conref-ids" tunnel="yes" select="$updated-conref-ids"/>
                            <xsl:with-param name="conrefend" select="$conrefend"/>
                            <xsl:with-param name="original-element" select="$original-element"/>
                            <xsl:with-param name="original-attributes" select="$original-attributes"/>
                          </xsl:apply-templates>
                          <xsl:if test="$target[2]">
                            <xsl:for-each select="$current-element">
                              <xsl:apply-templates select="." mode="ditamsg:duplicateConrefTarget"/>
                            </xsl:for-each>
                          </xsl:if>
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:apply-templates select="$current-element" mode="ditamsg:missing-conref-target-error"/>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:for-each>
              </xsl:when>
              <xsl:otherwise>
                <xsl:apply-templates select="." mode="ditamsg:strictConstraintMismatch"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="." mode="ditamsg:malformedConref"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
