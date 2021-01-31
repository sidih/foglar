<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
    extension-element-prefixes="ixsl"
    exclude-result-prefixes="#all"
    version="3.0">
    
    <xsl:param name="path-general">../../../</xsl:param>
    
    <xsl:param name="firstPB">01r</xsl:param>
    <xsl:param name="firstPoem">1</xsl:param>
    
    <xsl:template match="/">
        <!-- type = prikaz po straneh (page) ali prikaz po po besedilnih variantah (variant) -->
        <xsl:variable name="type" select="(ixsl:query-params()?type)"/>
        <!-- mode: 
              - pri page prikaz glede na način: različne kombinacije facs, dipl, crit; 
              - pri variant so avtometično vedno variatna mesta kot variant -->
        <xsl:variable name="mode" select="(ixsl:query-params()?mode)"/>
        <!-- prikaz posamezne strani (iz pb/@n, povezava pa seveda na @xml:id) -->
        <xsl:variable name="page" select="(ixsl:query-params()?page)"/>
        <!-- številka pesmi (iz div[@type='poem']/@n se ven poberejo številke) -->
        <xsl:variable name="poem" select="(ixsl:query-params()?poem)"/>
        <!-- prelomi vrstic: linebreak (boolean: 0 ali 1) -->
        <xsl:variable name="lb" select="(ixsl:query-params()?lb)"/>
        
        <xsl:variable name="pages">
            <xsl:for-each select="tei:TEI/tei:text/tei:body/tei:div[@xml:id='foglar-crit']//tei:pb">
                <page><xsl:value-of select="@n"/></page>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="previousPage" select="$pages/page[.=$page]/preceding-sibling::page[1]"/>
        <xsl:variable name="nextPage" select="$pages/page[.=$page]/following-sibling::page[1]"/>
        <xsl:variable name="poems">
            <xsl:for-each select="tei:TEI/tei:text/tei:body/tei:div[@xml:id='foglar-dipl']/tei:div/tei:div[@type='poem']">
                <xsl:if test="count(tei:lg[1]/tei:l[1]/tei:app/*) gt 0">
                    <poem>
                        <xsl:attribute name="title">
                            <xsl:variable name="title-from-head">
                                <xsl:choose>
                                    <xsl:when test="tei:head[1]/tei:app">
                                        <xsl:apply-templates select="tei:head[1]/tei:app/tei:rdg" mode="besedilo"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:apply-templates select="tei:head[1]" mode="besedilo"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:variable>
                            <xsl:value-of select="normalize-space($title-from-head)"/>
                        </xsl:attribute>
                        <xsl:attribute name="versions">
                            <xsl:value-of select="count(tei:lg[1]/tei:l[1]/tei:app/*)"/>
                        </xsl:attribute>
                        <xsl:attribute name="id">
                            <xsl:value-of select="@xml:id"/>
                        </xsl:attribute>
                        <!-- vrednost iz atributa n -->
                        <xsl:value-of select="@n"/>
                    </poem>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="previousPoem" select="$poems/poem[.=$poem]/preceding-sibling::poem[1]"/>
        <xsl:variable name="nextPoem" select="$poems/poem[.=$poem]/following-sibling::poem[1]"/>
        <xsl:variable name="poemTitle" select="$poems/poem[.=$poem]/@title"/>
        <xsl:variable name="poemTitle-short" select="concat(substring($poemTitle,1,30), if (string-length($poemTitle) gt 30) then ' […]' else '')"/>
        <xsl:variable name="numOfCollums" select="$poems/poem[. = $poem]/@versions"/>
        <xsl:variable name="poemID" select="$poems/poem[. = $poem]/@id"/>
        
        <xsl:result-document href="#para" method="ixsl:replace-content">
            <p class="show-for-small-only">Na malih zaslonih vzporednih prikazi ne delujejo optimalno. En prikaz je pod drugim.</p>
            <!-- V prvi vrstici
                 - v prvem (levem) stolpcu najprej izberemo tip prikazovanja (strani ali variante), -->
            <div class="row">
                <div class="medium-4 columns">
                    <div class="dropdown">
                        <button class="dropdown button">
                            <xsl:choose>
                                <xsl:when test="$type">
                                    <xsl:value-of select="concat('Vrsta prikaza ', if ($type='page') then '(strani)' else '(variantna mesta)')"/>
                                </xsl:when>
                                <xsl:otherwise>Izberi vrsto prikaza</xsl:otherwise>
                            </xsl:choose>
                        </button>
                        <div class="dropdown-content">
                            <!-- privzeto prikaže facs-dipl-crit -->
                            <a href="foglar-para.html?type=page&amp;mode=facs-dipl-crit&amp;page={if ($page) then $page else $firstPB}&amp;lb={if ($lb) then $lb else '1'}">
                                <xsl:if test="$type = 'page'">
                                    <xsl:attribute name="class">active</xsl:attribute>
                                </xsl:if>
                                <xsl:text>Po straneh</xsl:text>
                            </a>
                            <!-- Pri variantnih mestih je vedno privzeto variant) -->
                            <a href="foglar-para.html?type=variant&amp;mode=variant&amp;poem={if ($poem) then $poem else $firstPoem}&amp;lb={if ($lb) then $lb else '1'}">
                                <xsl:if test="$type = 'section'">
                                    <xsl:attribute name="class">active</xsl:attribute>
                                </xsl:if>
                                <xsl:text>Po variantnih mestih</xsl:text>
                            </a>
                        </div>
                    </div>
                </div>
                <!-- V prvi vrstici:
                      - v drugem (srednjem) stolpcu nato glede na prejšnjo izbiro tipa (strani ali variantna mesta)
                        pri stranek izberem vrsto (mode) prikazovanja (različne kombinacije faksimilov in diplomatičnega in kritičnega prepisa),
                        pri variantnih mestih pa so glede na številke poem dodani naslovi
                 -->
                <div class="medium-4 columns">
                    <xsl:if test="$type='page'">
                        <div class="dropdown">
                            <button class="secondary dropdown button">
                                <xsl:if test="$mode">
                                    <xsl:attribute name="style">background: #8e130b;</xsl:attribute>
                                </xsl:if>
                                <xsl:choose>
                                    <xsl:when test="$mode">
                                        <xsl:value-of select="concat('Način vzporednega prikaza (',$mode,')')"/>
                                    </xsl:when>
                                    <xsl:otherwise>Izberi način vzporednega prikaza</xsl:otherwise>
                                </xsl:choose>
                            </button>
                            <div class="dropdown-content">
                                <a href="foglar-para.html?type=page&amp;mode=facs-dipl&amp;page={if ($page) then $page else $firstPB}&amp;lb={if ($lb) then $lb else '1'}">
                                    <xsl:if test="$mode = 'facs-dipl'">
                                        <xsl:attribute name="class">active</xsl:attribute>
                                    </xsl:if>
                                    <xsl:text>Faksimile / Diplomatični prepis</xsl:text>
                                </a>
                                <a href="foglar-para.html?type=page&amp;mode=facs-crit&amp;page={if ($page) then $page else $firstPB}&amp;lb={if ($lb) then $lb else '1'}">
                                    <xsl:if test="$mode = 'facs-crit'">
                                        <xsl:attribute name="class">active</xsl:attribute>
                                    </xsl:if>
                                    <xsl:text>Faksimile / Kritični prepis</xsl:text>
                                </a>
                                <a href="foglar-para.html?type=page&amp;mode=dipl-crit&amp;page={if ($page) then $page else $firstPB}&amp;lb={if ($lb) then $lb else '1'}">
                                    <xsl:if test="$mode = 'dipl-crit'">
                                        <xsl:attribute name="class">active</xsl:attribute>
                                    </xsl:if>
                                    <xsl:text>Diplomatični / Kritični prepis</xsl:text>
                                </a>
                                <a href="foglar-para.html?type=page&amp;mode=facs-dipl-crit&amp;page={if ($page) then $page else $firstPB}&amp;lb={if ($lb) then $lb else '1'}">
                                    <xsl:if test="$mode = 'facs-dipl-crit'">
                                        <xsl:attribute name="class">active</xsl:attribute>
                                    </xsl:if>
                                    <xsl:text>Faksimile / Diplomatični / Kritični prepis</xsl:text>
                                </a>
                            </div>
                        </div>
                    </xsl:if>
                    <xsl:if test="$type='variant'">
                        <div class="dropdown">
                            <button class="secondary dropdown button">
                                <xsl:if test="$mode">
                                    <xsl:attribute name="style">background: #8e130b;</xsl:attribute>
                                </xsl:if>
                                <xsl:choose>
                                    <xsl:when test="$poem">
                                        <xsl:value-of select="concat($poem,': ',$poemTitle-short)"/>
                                    </xsl:when>
                                    <xsl:otherwise>Izberi pesem</xsl:otherwise>
                                </xsl:choose>
                            </button>
                            <div class="dropdown-content">
                                <xsl:for-each select="$poems/poem">
                                    <a href="foglar-para.html?type=variant&amp;mode=variant&amp;poem={.}&amp;lb={if ($lb) then $lb else '1'}">
                                        <xsl:if test=". = $poem">
                                            <xsl:attribute name="class">active</xsl:attribute>
                                        </xsl:if>
                                        <xsl:value-of select="concat(.,': ',@title)"/>
                                    </a>
                                </xsl:for-each>
                            </div>
                        </div>
                    </xsl:if>
                </div>
                <!-- V prvi vrstici: 
                     - v tretjem (najbolj desnem) stolpcu) je vklop ali izklop parametra za prikaz preloma vrstic -->
                <div class="medium-4 columns">
                    <xsl:if test="$mode">
                        <dir class="row">
                            <div class="small-6 columns text-right">
                                <p>Prelom vrstice:</p>
                            </div>
                            <div class="small-6 columns">
                                <div class="secondary button-group">
                                    <a class="button" href="foglar-para.html?type={$type}&amp;mode={$mode}&amp;{if ($page) then ('page='||$page) else ('poem='||$poem)}&amp;lb=1">
                                        <xsl:if test="$lb='1'">
                                            <xsl:attribute name="style">background: #8e130b;</xsl:attribute>
                                        </xsl:if>
                                        <xsl:text>Da</xsl:text>
                                    </a>
                                    <a class="button" href="foglar-para.html?type={$type}&amp;mode={$mode}&amp;{if ($page) then ('page='||$page) else ('poem='||$poem)}&amp;lb=0">
                                        <xsl:if test="$lb='0'">
                                            <xsl:attribute name="style">background: #8e130b;</xsl:attribute>
                                        </xsl:if>
                                        <xsl:text>Ne</xsl:text>
                                    </a>
                                </div>
                            </div>
                        </dir>
                    </xsl:if>
                </div>
            </div>
            <xsl:if test="$type and $mode and ($page or $poem)">
                <!-- Različni prikazi strani -->
                <xsl:if test="$type='page'">
                    <!-- spodnje štiri variable pretvorijo številke strani v pb/@xml:id za diplomatičen in kritičen prepis -->
                    <xsl:variable name="page-start-dipl">
                        <xsl:call-template name="page-start">
                            <xsl:with-param name="page" select="$page"/>
                            <xsl:with-param name="content-type">dipl</xsl:with-param>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:variable name="page-end-dipl">
                        <xsl:call-template name="page-end">
                            <xsl:with-param name="nextPage" select="$nextPage"/>
                            <xsl:with-param name="content-type">dipl</xsl:with-param>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:variable name="page-start-crit">
                        <xsl:call-template name="page-start">
                            <xsl:with-param name="page" select="$page"/>
                            <xsl:with-param name="content-type">crit</xsl:with-param>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:variable name="page-end-crit">
                        <xsl:call-template name="page-end">
                            <xsl:with-param name="nextPage" select="$nextPage"/>
                            <xsl:with-param name="content-type">crit</xsl:with-param>
                        </xsl:call-template>
                    </xsl:variable>
                    <!-- Pred glavno vsebino na vrhu najprej prikažemo vrstico za premikanje naprej in nazaj po straneh (isto kot spodaj):
                         skupaj z možnostjo vpisa številke strani
                    -->
                    <div class="row">
                        <div class="small-3 columns">
                            <p>
                                <xsl:if test="$previousPage != ''">
                                    <a class="button" href="foglar-para.html?type={$type}&amp;mode={$mode}&amp;page={$previousPage}&amp;lb={$lb}">
                                        <xsl:value-of select="concat($previousPage,' &lt;&lt;')"/>
                                    </a>
                                </xsl:if>
                            </p>
                        </div>
                        <div class="small-6 columns">
                            <form action="foglar-para.html" autocomplete="off">
                                <div class="row collapse">
                                    <div class="small-4 columns text-right">
                                        <button class="button" type="submit">stran</button>
                                    </div>
                                    <div class="small-8 columns text-left">
                                        <input type="hidden" name="type" value="{$type}"/>
                                        <input type="hidden" name="mode" value="{$mode}"/>
                                        <input type="text" name="page" list="pages" placeholder="{$page}"/>
                                        <input type="hidden" name="lb" value="{$lb}"/>
                                    </div>
                                </div>
                            </form>
                            <!-- autocomplete list -->
                            <datalist id="pages">
                                <xsl:for-each select="$pages/page">
                                    <option>
                                        <xsl:value-of select="."/>
                                    </option>
                                </xsl:for-each>
                            </datalist>
                        </div>
                        <div class="small-3 columns text-right">
                            <p>
                                <xsl:if test="$nextPage != ''">
                                    <a class="button" href="foglar-para.html?type={$type}&amp;mode={$mode}&amp;page={$nextPage}&amp;lb={$lb}">
                                        <xsl:value-of select="concat('&gt;&gt; ',$nextPage)"/>
                                    </a>
                                </xsl:if>
                            </p>
                        </div>
                    </div>
                    <!-- začetek procesiranja vseh štirih možnih pogledov -->
                    <xsl:if test="$mode='facs-dipl'">
                        <div class="row border-content">
                            <div class="medium-6 columns border-content-inner">
                                <xsl:call-template name="pannable-image">
                                    <xsl:with-param name="page" select="$page"/>
                                </xsl:call-template>
                            </div>
                            <div class="medium-6 columns border-content-inner">
                                <xsl:call-template name="process-content">
                                    <xsl:with-param name="type" select="$type"/>
                                    <xsl:with-param name="mode" select="$mode"/>
                                    <xsl:with-param name="content-start" select="$page-start-dipl"/>
                                    <xsl:with-param name="content-end" select="$page-end-dipl"/>
                                    <xsl:with-param name="content-type">dipl</xsl:with-param>
                                    <xsl:with-param name="lb" select="$lb"/>
                                </xsl:call-template>
                            </div>
                        </div>
                    </xsl:if>
                    <xsl:if test="$mode='facs-crit'">
                        <div class="row border-content">
                            <div class="medium-6 columns border-content-inner">
                                <xsl:call-template name="pannable-image">
                                    <xsl:with-param name="page" select="$page"/>
                                </xsl:call-template>
                            </div>
                            <div class="medium-6 columns border-content-inner">
                                <xsl:call-template name="process-content">
                                    <xsl:with-param name="type" select="$type"/>
                                    <xsl:with-param name="mode" select="$mode"/>
                                    <xsl:with-param name="content-start" select="$page-start-crit"/>
                                    <xsl:with-param name="content-end" select="$page-end-crit"/>
                                    <xsl:with-param name="content-type">crit</xsl:with-param>
                                    <xsl:with-param name="lb" select="$lb"/>
                                </xsl:call-template>
                            </div>
                        </div>
                    </xsl:if>
                    <xsl:if test="$mode='dipl-crit'">
                        <div class="row border-content">
                            <div class="medium-6 columns border-content-inner">
                                <xsl:call-template name="process-content">
                                    <xsl:with-param name="type" select="$type"/>
                                    <xsl:with-param name="mode" select="$mode"/>
                                    <xsl:with-param name="content-start" select="$page-start-dipl"/>
                                    <xsl:with-param name="content-end" select="$page-end-dipl"/>
                                    <xsl:with-param name="content-type">dipl</xsl:with-param>
                                    <xsl:with-param name="lb" select="$lb"/>
                                </xsl:call-template>
                            </div>
                            <div class="medium-6 columns border-content-inner">
                                <xsl:call-template name="process-content">
                                    <xsl:with-param name="type" select="$type"/>
                                    <xsl:with-param name="mode" select="$mode"/>
                                    <xsl:with-param name="content-start" select="$page-start-crit"/>
                                    <xsl:with-param name="content-end" select="$page-end-crit"/>
                                    <xsl:with-param name="content-type">crit</xsl:with-param>
                                    <xsl:with-param name="lb" select="$lb"/>
                                </xsl:call-template>
                            </div>
                        </div>
                    </xsl:if>
                    <xsl:if test="$mode='facs-dipl-crit'">
                        <div class="row border-content">
                            <div class="medium-4 columns border-content-inner">
                                <xsl:call-template name="pannable-image">
                                    <xsl:with-param name="page" select="$page"/>
                                </xsl:call-template>
                            </div>
                            <div class="medium-4 columns border-content-inner">
                                <xsl:call-template name="process-content">
                                    <xsl:with-param name="type" select="$type"/>
                                    <xsl:with-param name="mode" select="$mode"/>
                                    <xsl:with-param name="content-start" select="$page-start-dipl"/>
                                    <xsl:with-param name="content-end" select="$page-end-dipl"/>
                                    <xsl:with-param name="content-type">dipl</xsl:with-param>
                                    <xsl:with-param name="lb" select="$lb"/>
                                </xsl:call-template>
                            </div>
                            <div class="medium-4 columns border-content-inner">
                                <xsl:call-template name="process-content">
                                    <xsl:with-param name="type" select="$type"/>
                                    <xsl:with-param name="mode" select="$mode"/>
                                    <xsl:with-param name="content-start" select="$page-start-crit"/>
                                    <xsl:with-param name="content-end" select="$page-end-crit"/>
                                    <xsl:with-param name="content-type">crit</xsl:with-param>
                                    <xsl:with-param name="lb" select="$lb"/>
                                </xsl:call-template>
                            </div>
                        </div>
                    </xsl:if>
                    <!-- prikažemo še povezavo na to stran v okviru prikaza celotne vsebine diplomatičnega ali kritičnega prepisa -->
                    <div class="row show-for-medium">
                        <div class="medium-{if ($mode='facs-dipl-crit') then '4' else '6'} columns text-center">
                            <xsl:choose>
                                <xsl:when test="tokenize($mode,'-')[1] = 'facs'">
                                    <p></p>
                                </xsl:when>
                                <xsl:otherwise>
                                    <a class="button" href="foglar-dipl.html#{$page-start-dipl}">Celotno besedilo</a>
                                </xsl:otherwise>
                            </xsl:choose>
                        </div>
                        <div class="medium-{if ($mode='facs-dipl-crit') then '4' else '6'} columns text-center">
                            <xsl:if test="tokenize($mode,'-')[2] = 'dipl'">
                                <a class="button" href="foglar-dipl.html#{$page-start-dipl}">Celotno besedilo</a>
                            </xsl:if>
                            <xsl:if test="tokenize($mode,'-')[2] = 'crit'">
                                <a class="button" href="foglar-crit.html#{$page-start-crit}">Celotno besedilo</a>
                            </xsl:if>
                        </div>
                        <xsl:if test="$mode='facs-dipl-crit'">
                            <div class="medium-4 columns text-center">
                                <a class="button" href="foglar-crit.html#{$page-start-crit}">Celotno besedilo</a>
                            </div>
                        </xsl:if>
                    </div>
                    <!-- na koncu nato pod glavno vsebino prikažemo vrstico za premikanje naprej in nazaj po straneh -->
                    <div class="row">
                        <div class="small-6 columns text-center">
                            <p>
                                <xsl:if test="$previousPage != ''">
                                    <a class="button" href="foglar-para.html?type={$type}&amp;mode={$mode}&amp;page={$previousPage}&amp;lb={$lb}">
                                        <xsl:value-of select="concat($previousPage,' &lt;&lt;')"/>
                                    </a>
                                </xsl:if>
                            </p>
                        </div>
                        <div class="small-6 columns text-center">
                            <p>
                                <xsl:if test="$nextPage != ''">
                                    <a class="button" href="foglar-para.html?type={$type}&amp;mode={$mode}&amp;page={$nextPage}&amp;lb={$lb}">
                                        <xsl:value-of select="concat('&gt;&gt; ',$nextPage)"/>
                                    </a>
                                </xsl:if>
                            </p>
                        </div>
                    </div>
                </xsl:if>
                
                <!-- procesiranje variantnih mest: trenutno je samo en mode (variant), ki velja samo za diplomatični prikaz -->
                <xsl:if test="$type='variant' and $mode='variant'">
                    <!-- premikanje naprej in nazaj po pesmih -->
                    <div class="row">
                        <div class="small-3 columns">
                            <p>
                                <xsl:if test="$previousPoem != ''">
                                    <a class="button" href="foglar-para.html?type={$type}&amp;mode={$mode}&amp;poem={$previousPoem}&amp;lb={$lb}">
                                        <xsl:value-of select="concat($previousPoem,' &lt;&lt;')"/>
                                    </a>
                                </xsl:if>
                            </p>
                        </div>
                        <div class="small-6 columns text-center">
                            <h3>
                                <xsl:value-of select="$poemTitle"/>
                            </h3>
                        </div>
                        <div class="small-3 columns text-right">
                            <p>
                                <xsl:if test="$nextPoem != ''">
                                    <a class="button" href="foglar-para.html?type={$type}&amp;mode={$mode}&amp;poem={$nextPoem}&amp;lb={$lb}">
                                        <xsl:value-of select="concat('&gt;&gt; ',$nextPoem)"/>
                                    </a>
                                </xsl:if>
                            </p>
                        </div>
                    </div>
                    <div class="row border-content">
                        <!-- trenutno je tako, da obstajajo največ tri možnosti variantnih mest, zato so možni samo 2 ali 3. stolpci -->
                        <!-- content-type je vedno dipl, saj se variantna mesta nahajajo samo tam -->
                        <!-- content-start in content-end parametra imata vedno isto vrednost: številko posmi -->
                        <!-- doda se parameter z identifikatorjem priče/witness: wit -->
                        <div class="medium-{if ($numOfCollums = 3) then 4 else 6} columns border-content-inner">
                            <xsl:variable name="wit1" select="tei:TEI/tei:text/tei:body/tei:div[@xml:id='foglar-dipl']/tei:div/tei:div[@type='poem'][@n=$poem]/tei:lg[1]/tei:l[1]/tei:app/tei:lem/substring(@wit,2)"/>
                            <div class="callout secondary" data-closable="">
                                <xsl:for-each select="tei:TEI/tei:text/tei:front/tei:div[3]/tei:listWit/tei:witness[@xml:id=$wit1]">
                                    <h5>
                                        <xsl:value-of select="tei:label"/>
                                    </h5>
                                    <p>
                                        <xsl:apply-templates select="tei:bibl" mode="witness-description"/>
                                    </p>
                                </xsl:for-each>
                                <button class="close-button" aria-label="Dismiss alert" type="button" data-close="" style="background-color: inherit;">
                                    <span aria-hidden="true">&#xD7;</span>
                                </button>
                            </div>
                            <xsl:call-template name="process-content">
                                <xsl:with-param name="type" select="$type"/>
                                <xsl:with-param name="mode" select="$mode"/>
                                <xsl:with-param name="content-start" select="$poem"/>
                                <xsl:with-param name="content-end" select="$nextPoem"/>
                                <xsl:with-param name="content-type">dipl</xsl:with-param>
                                <xsl:with-param name="lb" select="$lb"/>
                                <xsl:with-param name="wit" select="$wit1"/>
                            </xsl:call-template>
                        </div>
                        <div class="medium-{if ($numOfCollums = 3) then 4 else 6} columns border-content-inner">
                            <xsl:variable name="wit2" select="tei:TEI/tei:text/tei:body/tei:div[@xml:id='foglar-dipl']/tei:div/tei:div[@type='poem'][@n=$poem]/tei:lg[1]/tei:l[1]/tei:app/tei:rdg[1]/substring(@wit,2)"/>
                            <div class="callout secondary" data-closable="">
                                <xsl:for-each select="tei:TEI/tei:text/tei:front/tei:div[3]/tei:listWit/tei:witness[@xml:id=$wit2]">
                                    <h5>
                                        <xsl:value-of select="tei:label"/>
                                    </h5>
                                    <p>
                                        <xsl:apply-templates select="tei:bibl" mode="witness-description"/>
                                    </p>
                                </xsl:for-each>
                                <button class="close-button" aria-label="Dismiss alert" type="button" data-close="" style="background-color: inherit;">
                                    <span aria-hidden="true">&#xD7;</span>
                                </button>
                            </div>
                            <xsl:call-template name="process-content">
                                <xsl:with-param name="type" select="$type"/>
                                <xsl:with-param name="mode" select="$mode"/>
                                <xsl:with-param name="content-start" select="$poem"/>
                                <xsl:with-param name="content-end" select="$nextPoem"/>
                                <xsl:with-param name="content-type">dipl</xsl:with-param>
                                <xsl:with-param name="lb" select="$lb"/>
                                <xsl:with-param name="wit" select="$wit2"/>
                            </xsl:call-template>
                        </div>
                        <xsl:if test="$numOfCollums = 3">
                            <div class="medium-4 columns border-content-inner">
                                <xsl:variable name="wit3" select="tei:TEI/tei:text/tei:body/tei:div[@xml:id='foglar-dipl']/tei:div/tei:div[@type='poem'][@n=$poem]/tei:lg[1]/tei:l[1]/tei:app/tei:rdg[2]/substring(@wit,2)"/>
                                <div class="callout secondary" data-closable="">
                                    <xsl:for-each select="tei:TEI/tei:text/tei:front/tei:div[3]/tei:listWit/tei:witness[@xml:id=$wit3]">
                                        <h5>
                                            <xsl:value-of select="tei:label"/>
                                        </h5>
                                        <p>
                                            <xsl:apply-templates select="tei:bibl" mode="witness-description"/>
                                        </p>
                                    </xsl:for-each>
                                    <button class="close-button" aria-label="Dismiss alert" type="button" data-close="" style="background-color: inherit;">
                                        <span aria-hidden="true">&#xD7;</span>
                                    </button>
                                </div>
                                <xsl:call-template name="process-content">
                                    <xsl:with-param name="type" select="$type"/>
                                    <xsl:with-param name="mode" select="$mode"/>
                                    <xsl:with-param name="content-start" select="$poem"/>
                                    <xsl:with-param name="content-end" select="$nextPoem"/>
                                    <xsl:with-param name="content-type">dipl</xsl:with-param>
                                    <xsl:with-param name="lb" select="$lb"/>
                                    <xsl:with-param name="wit" select="$wit3"/>
                                </xsl:call-template>
                            </div>
                        </xsl:if>
                    </div>
                    <!-- prikažemo še povezavo na to sklop v okviru prikaza celotne vsebine diplomatičnega ali kritičnega prepisa -->
                    <div class="row show-for-medium">
                        <div class="medium-{if ($numOfCollums = 3) then 4 else 6} columns text-center">
                            <a class="button" href="foglar-dipl.html#{$poemID}">Celotno besedilo</a>
                        </div>
                        <div class="medium-{if ($numOfCollums = 3) then 4 else 6} columns text-center">
                            <p></p>
                        </div>
                        <xsl:if test="$numOfCollums = 3">
                            <div class="medium-4 columns border-content-inner">
                                <p></p>
                            </div>
                        </xsl:if>
                    </div>
                    <!-- premikanje naprej in nazaj po pesmih -->
                    <div class="row">
                        <div class="small-3 columns">
                            <p>
                                <xsl:if test="$previousPoem != ''">
                                    <a class="button" href="foglar-para.html?type={$type}&amp;mode={$mode}&amp;poem={$previousPoem}&amp;lb={$lb}">
                                        <xsl:value-of select="concat($previousPoem,' &lt;&lt;')"/>
                                    </a>
                                </xsl:if>
                            </p>
                        </div>
                        <div class="small-6 columns text-center">
                            <h3>
                                <xsl:value-of select="$poemTitle"/>
                            </h3>
                        </div>
                        <div class="small-3 columns text-right">
                            <p>
                                <xsl:if test="$nextPoem != ''">
                                    <a class="button" href="foglar-para.html?type={$type}&amp;mode={$mode}&amp;poem={$nextPoem}&amp;lb={$lb}">
                                        <xsl:value-of select="concat('&gt;&gt; ',$nextPoem)"/>
                                    </a>
                                </xsl:if>
                            </p>
                        </div>
                    </div>
                    <!-- JavaScript (jQuery) za hoover čez lem in rdg elemente istega app (izvorna koda iz http://jsfiddle.net/aZXRM/) -->
                    <script>
                        <xsl:text>function highlightAllOnMouseover(className){
                            $(className).mouseover(function() {
                          $(className).css("background-color", "transparent"); 
                          $(className).css("background-color", "yellow");
                        }).mouseleave(function() { 
                            $(className).css("background-color", "transparent");
                        });
                        }</xsl:text>
                        <xsl:for-each select="tei:TEI/tei:text/tei:body/tei:div[@xml:id='foglar-dipl']/tei:div/tei:div[@type='poem'][@n=$poem]//tei:app">
                            <xsl:text>highlightAllOnMouseover(".</xsl:text>
                            <xsl:value-of select="@xml:id"/>
                            <xsl:text>");</xsl:text>
                        </xsl:for-each>
                    </script>
                </xsl:if>
            </xsl:if>
            <!-- še za prikaz opisov -->
            <script>
                $(document).ready(function () {
                  $('.term').on( "click", function(event) {
                    event.stopPropagation();
                    var id = $(event.target).data('explain');
                    $('#' + id).toggle();
                  });
                  $('.term-sup').on( "click", function(event) {
                    event.stopPropagation();
                    var id = $(event.target).data('explain');
                    $('#' + id).toggle();
                  });
                })
            </script>
        </xsl:result-document>
    </xsl:template>
    
    <xsl:template match="tei:ref" mode="witness-description">
        <a href="{@target}" target="_blank">
            <xsl:apply-templates mode="witness-description"/>
        </a>
    </xsl:template>
    
    <xsl:template name="page-start">
        <xsl:param name="page"/>
        <xsl:param name="content-type"/>
        <xsl:value-of select="//tei:pb[@n=$page][matches(@xml:id,$content-type)]/@xml:id"/>
    </xsl:template>
    
    <xsl:template name="page-end">
        <xsl:param name="nextPage"/>
        <xsl:param name="content-type"/>
        <xsl:if test="$nextPage != ''">
            <xsl:value-of select="//tei:pb[@n=$nextPage][matches(@xml:id,$content-type)]/@xml:id"/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="pannable-image">
        <xsl:param name="page"/>
        <img id="image" src="http://nl.ijs.si/e-zrc/foglar/facs/orig/ms_123_{$page}.jpg"/>
        <!--<img id="image" src="facs/orig/{$image-name}.jpg"/>-->
        <script>
            var image = document.getElementById('image');
            var viewer = new Viewer(image, {
            inline: true,
            navbar: false,
            title: false,
            toolbar: false
            });
        </script>
    </xsl:template>
    
    <xsl:template name="process-content">
        <xsl:param name="type"/>
        <xsl:param name="mode"/>
        <xsl:param name="content-start"/>
        <xsl:param name="content-end"/>
        <xsl:param name="content-type"/>
        <xsl:param name="lb"/>
        <xsl:param name="wit"/>
        <xsl:variable name="content">
            <xsl:if test="$type='page'">
                <!-- Za $content-type dipl in crit -->
                <xsl:apply-templates select="tei:TEI/tei:text/tei:body/tei:div[@xml:id=concat('foglar-',$content-type)]/tei:div/*">
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="mode" select="$mode"/>
                    <xsl:with-param name="content-start" select="$content-start"/>
                    <xsl:with-param name="content-end" select="$content-end"/>
                    <xsl:with-param name="content-type" select="$content-type"/>
                    <xsl:with-param name="lb" select="$lb"/>
                    <xsl:with-param name="wit" select="$wit"/>
                </xsl:apply-templates>
            </xsl:if>
            <xsl:if test="$type='variant'">
                <xsl:apply-templates select="tei:TEI/tei:text/tei:body/tei:div[@xml:id='foglar-dipl']/tei:div/tei:div[@type='poem'][@n=$content-start]/*">
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="mode" select="$mode"/>
                    <xsl:with-param name="content-start" select="$content-start"/>
                    <xsl:with-param name="content-end" select="$content-end"/>
                    <xsl:with-param name="content-type" select="$content-type"/>
                    <xsl:with-param name="lb" select="$lb"/>
                    <xsl:with-param name="wit" select="$wit"/>
                </xsl:apply-templates>
            </xsl:if>
        </xsl:variable>
        <!-- Vsebina -->
        <xsl:choose>
            <xsl:when test="$type='page' and string-length($content) = 0">
                <div class="warning callout">
                    <h5>Stran ne obstaja!</h5>
                    <p>Izbrana stran ne obstaja. Iz spustnega seznama strani izberite obstoječo stran.</p>
                </div>
            </xsl:when>
            <xsl:when test="$type='variant' and string-length($content) = 0">
                <div class="warning callout">
                    <h5>Pesem ne obstaja!</h5>
                    <p>Izbrana pesem ne obstaja. Iz spustnega seznama strani izberite obstoječo pesem.</p>
                </div>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="$content"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="tei:pb">
        <!-- pb ne procesiram  -->
    </xsl:template>
    
    <xsl:template match="tei:fw">
        <xsl:param name="type"/>
        <xsl:param name="mode"/>
        <xsl:param name="content-start"/>
        <xsl:param name="content-end"/>
        <xsl:param name="content-type"/>
        <xsl:param name="lb"/>
        <xsl:param name="wit"/>
        <xsl:if test="$type='page'">
            <xsl:if test="if ($content-end='') then (preceding::tei:pb[1][@xml:id=$content-start]) else (preceding::tei:pb[1][@xml:id=$content-start]  and following::tei:pb[1][@xml:id=$content-end])">
                <div class="pageNum">
                    <xsl:apply-templates>
                        <xsl:with-param name="type" select="$type"/>
                        <xsl:with-param name="mode" select="$mode"/>
                        <xsl:with-param name="content-start" select="$content-start"/>
                        <xsl:with-param name="content-end" select="$content-end"/>
                        <xsl:with-param name="content-type" select="$content-type"/>
                        <xsl:with-param name="lb" select="$lb"/>
                        <xsl:with-param name="wit" select="$wit"/>
                    </xsl:apply-templates>
                </div>
            </xsl:if>
        </xsl:if>
        <xsl:if test="$type='variant'">
            <div class="pageNum">
                <xsl:apply-templates>
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="mode" select="$mode"/>
                    <xsl:with-param name="content-start" select="$content-start"/>
                    <xsl:with-param name="content-end" select="$content-end"/>
                    <xsl:with-param name="content-type" select="$content-type"/>
                    <xsl:with-param name="lb" select="$lb"/>
                    <xsl:with-param name="wit" select="$wit"/>
                </xsl:apply-templates>
            </div>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="tei:div">
        <xsl:param name="type"/>
        <xsl:param name="mode"/>
        <xsl:param name="content-start"/>
        <xsl:param name="content-end"/>
        <xsl:param name="content-type"/>
        <xsl:param name="lb"/>
        <xsl:param name="wit"/>
        <xsl:if test="$type='page'">
            <xsl:choose>
                <xsl:when test="if ($content-end='') then (preceding::tei:pb[1][@xml:id=$content-start]) else (preceding::tei:pb[1][@xml:id=$content-start]  and following::tei:pb[1][@xml:id=$content-end])">
                    <xsl:apply-templates>
                        <xsl:with-param name="type" select="$type"/>
                        <xsl:with-param name="mode" select="$mode"/>
                        <xsl:with-param name="content-start" select="$content-start"/>
                        <xsl:with-param name="content-end" select="$content-end"/>
                        <xsl:with-param name="content-type" select="$content-type"/>
                        <xsl:with-param name="lb" select="$lb"/>
                        <xsl:with-param name="wit" select="$wit"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:choose>
                        <xsl:when test="descendant::tei:pb[@xml:id=$content-start] or descendant::tei:pb[@xml:id=$content-end]">
                            <xsl:apply-templates>
                                <xsl:with-param name="type" select="$type"/>
                                <xsl:with-param name="mode" select="$mode"/>
                                <xsl:with-param name="content-start" select="$content-start"/>
                                <xsl:with-param name="content-end" select="$content-end"/>
                                <xsl:with-param name="content-type" select="$content-type"/>
                                <xsl:with-param name="lb" select="$lb"/>
                                <xsl:with-param name="wit" select="$wit"/>
                            </xsl:apply-templates>
                        </xsl:when>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <xsl:if test="$type='variant'">
            <xsl:apply-templates>
                <xsl:with-param name="type" select="$type"/>
                <xsl:with-param name="mode" select="$mode"/>
                <xsl:with-param name="content-start" select="$content-start"/>
                <xsl:with-param name="content-end" select="$content-end"/>
                <xsl:with-param name="content-type" select="$content-type"/>
                <xsl:with-param name="lb" select="$lb"/>
                <xsl:with-param name="wit" select="$wit"/>
            </xsl:apply-templates>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="tei:app">
        <xsl:param name="type"/>
        <xsl:param name="mode"/>
        <xsl:param name="content-start"/>
        <xsl:param name="content-end"/>
        <xsl:param name="content-type"/>
        <xsl:param name="lb"/>
        <xsl:param name="wit"/>
        <xsl:if test="$type='page'">
            <xsl:if test="if ($content-end='') then (preceding::tei:pb[1][@xml:id=$content-start]) else (preceding::tei:pb[1][@xml:id=$content-start]  and following::tei:pb[1][@xml:id=$content-end])">
                <xsl:apply-templates>
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="mode" select="$mode"/>
                    <xsl:with-param name="content-start" select="$content-start"/>
                    <xsl:with-param name="content-end" select="$content-end"/>
                    <xsl:with-param name="content-type" select="$content-type"/>
                    <xsl:with-param name="lb" select="$lb"/>
                    <xsl:with-param name="wit" select="$wit"/>
                </xsl:apply-templates>
            </xsl:if>
        </xsl:if>
        <xsl:if test="$type='variant'">
            <xsl:apply-templates>
                <xsl:with-param name="type" select="$type"/>
                <xsl:with-param name="mode" select="$mode"/>
                <xsl:with-param name="content-start" select="$content-start"/>
                <xsl:with-param name="content-end" select="$content-end"/>
                <xsl:with-param name="content-type" select="$content-type"/>
                <xsl:with-param name="lb" select="$lb"/>
                <xsl:with-param name="wit" select="$wit"/>
            </xsl:apply-templates>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="tei:lem">
        <xsl:param name="type"/>
        <xsl:param name="mode"/>
        <xsl:param name="content-start"/>
        <xsl:param name="content-end"/>
        <xsl:param name="content-type"/>
        <xsl:param name="lb"/>
        <xsl:param name="wit"/>
        <xsl:if test="$type='page'">
            <xsl:if test="if ($content-end='') then (preceding::tei:pb[1][@xml:id=$content-start]) else (preceding::tei:pb[1][@xml:id=$content-start]  and following::tei:pb[1][@xml:id=$content-end])">
                <xsl:apply-templates>
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="mode" select="$mode"/>
                    <xsl:with-param name="content-start" select="$content-start"/>
                    <xsl:with-param name="content-end" select="$content-end"/>
                    <xsl:with-param name="content-type" select="$content-type"/>
                    <xsl:with-param name="lb" select="$lb"/>
                    <xsl:with-param name="wit" select="$wit"/>
                </xsl:apply-templates>
            </xsl:if>
        </xsl:if>
        <xsl:if test="$type='variant'">
            <xsl:if test="substring(@wit,2)=$wit">
                <xsl:choose>
                    <xsl:when test="string-length() = 0">
                        <span class="{parent::tei:app/@xml:id}">[…]</span>
                    </xsl:when>
                    <xsl:otherwise>
                        <span class="{parent::tei:app/@xml:id}">
                            <xsl:apply-templates>
                                <xsl:with-param name="type" select="$type"/>
                                <xsl:with-param name="mode" select="$mode"/>
                                <xsl:with-param name="content-start" select="$content-start"/>
                                <xsl:with-param name="content-end" select="$content-end"/>
                                <xsl:with-param name="content-type" select="$content-type"/>
                                <xsl:with-param name="lb" select="$lb"/>
                                <xsl:with-param name="wit" select="$wit"/>
                            </xsl:apply-templates>
                        </span>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="tei:rdg">
        <xsl:param name="type"/>
        <xsl:param name="mode"/>
        <xsl:param name="content-start"/>
        <xsl:param name="content-end"/>
        <xsl:param name="content-type"/>
        <xsl:param name="lb"/>
        <xsl:param name="wit"/>
        <xsl:if test="$type='page'">
            <!-- ne procesiram -->
        </xsl:if>
        <xsl:if test="$type='variant'">
            <xsl:if test="substring(@wit,2)=$wit">
                <xsl:choose>
                    <xsl:when test="string-length() = 0">
                        <span class="{parent::tei:app/@xml:id}">[…]</span>
                    </xsl:when>
                    <xsl:otherwise>
                        <span class="{parent::tei:app/@xml:id}">
                            <xsl:apply-templates>
                                <xsl:with-param name="type" select="$type"/>
                                <xsl:with-param name="mode" select="$mode"/>
                                <xsl:with-param name="content-start" select="$content-start"/>
                                <xsl:with-param name="content-end" select="$content-end"/>
                                <xsl:with-param name="content-type" select="$content-type"/>
                                <xsl:with-param name="lb" select="$lb"/>
                                <xsl:with-param name="wit" select="$wit"/>
                            </xsl:apply-templates>
                        </span>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="tei:head">
        <xsl:param name="type"/>
        <xsl:param name="mode"/>
        <xsl:param name="content-start"/>
        <xsl:param name="content-end"/>
        <xsl:param name="content-type"/>
        <xsl:param name="lb"/>
        <xsl:param name="wit"/>
        <xsl:if test="$type = 'page'">
            <!-- možen je pb tudi sredi head -->
            <xsl:choose>
                <xsl:when test="if ($content-end='') then (preceding::tei:pb[1][@xml:id=$content-start]) else (preceding::tei:pb[1][@xml:id=$content-start]  and following::tei:pb[1][@xml:id=$content-end])">
                    <xsl:call-template name="head">
                        <xsl:with-param name="type" select="$type"/>
                        <xsl:with-param name="mode" select="$mode"/>
                        <xsl:with-param name="content-start" select="$content-start"/>
                        <xsl:with-param name="content-end" select="$content-end"/>
                        <xsl:with-param name="content-type" select="$content-type"/>
                        <xsl:with-param name="lb" select="$lb"/>
                        <xsl:with-param name="wit" select="$wit"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:choose>
                        <xsl:when test="descendant::tei:pb[@xml:id=$content-start] or descendant::tei:pb[@xml:id=$content-end]">
                            <xsl:call-template name="head">
                                <xsl:with-param name="type" select="$type"/>
                                <xsl:with-param name="mode" select="$mode"/>
                                <xsl:with-param name="content-start" select="$content-start"/>
                                <xsl:with-param name="content-end" select="$content-end"/>
                                <xsl:with-param name="content-type" select="$content-type"/>
                                <xsl:with-param name="lb" select="$lb"/>
                                <xsl:with-param name="wit" select="$wit"/>
                            </xsl:call-template>
                        </xsl:when>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <xsl:if test="$type='variant'">
            <xsl:call-template name="head">
                <xsl:with-param name="type" select="$type"/>
                <xsl:with-param name="mode" select="$mode"/>
                <xsl:with-param name="content-start" select="$content-start"/>
                <xsl:with-param name="content-end" select="$content-end"/>
                <xsl:with-param name="content-type" select="$content-type"/>
                <xsl:with-param name="lb" select="$lb"/>
                <xsl:with-param name="wit" select="$wit"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    
    <!-- head ima lahko znotraj pb -->
    <xsl:template name="head">
        <xsl:param name="type"/>
        <xsl:param name="mode"/>
        <xsl:param name="content-start"/>
        <xsl:param name="content-end"/>
        <xsl:param name="content-type"/>
        <xsl:param name="lb"/>
        <xsl:param name="wit"/>
        <xsl:if test="parent::tei:div[@xml:id = 'foglar-crit.1' or @xml:id = 'foglar-dipl.1']">
            <h3>
                <xsl:choose>
                    <xsl:when test="if ($content-end='') then (preceding::tei:pb[1][@xml:id=$content-start]) else (preceding::tei:pb[1][@xml:id=$content-start]  and following::tei:pb[1][@xml:id=$content-end])">
                        <xsl:apply-templates>
                            <xsl:with-param name="type" select="$type"/>
                            <xsl:with-param name="mode" select="$mode"/>
                            <xsl:with-param name="content-start" select="$content-start"/>
                            <xsl:with-param name="content-end" select="$content-end"/>
                            <xsl:with-param name="content-type" select="$content-type"/>
                            <xsl:with-param name="lb" select="$lb"/>
                            <xsl:with-param name="wit" select="$wit"/>
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:choose>
                            <xsl:when test="descendant::tei:pb[@xml:id=$content-start] or descendant::tei:pb[@xml:id=$content-end]">
                                <xsl:choose>
                                    <xsl:when test="tei:pb[@xml:id=$content-start]">
                                        <xsl:apply-templates select="node()[preceding::tei:pb[1][@xml:id=$content-start]]">
                                            <xsl:with-param name="type" select="$type"/>
                                            <xsl:with-param name="mode" select="$mode"/>
                                            <xsl:with-param name="content-start" select="$content-start"/>
                                            <xsl:with-param name="content-end" select="$content-end"/>
                                            <xsl:with-param name="content-type" select="$content-type"/>
                                            <xsl:with-param name="lb" select="$lb"/>
                                            <xsl:with-param name="wit" select="$wit"/>
                                        </xsl:apply-templates>
                                    </xsl:when>
                                    <xsl:when test="tei:pb[@xml:id=$content-end]">
                                        <xsl:apply-templates select="node()[following::tei:pb[1][@xml:id=$content-end]]">
                                            <xsl:with-param name="type" select="$type"/>
                                            <xsl:with-param name="mode" select="$mode"/>
                                            <xsl:with-param name="content-start" select="$content-start"/>
                                            <xsl:with-param name="content-end" select="$content-end"/>
                                            <xsl:with-param name="content-type" select="$content-type"/>
                                            <xsl:with-param name="lb" select="$lb"/>
                                            <xsl:with-param name="wit" select="$wit"/>
                                        </xsl:apply-templates>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:apply-templates>
                                            <xsl:with-param name="type" select="$type"/>
                                            <xsl:with-param name="mode" select="$mode"/>
                                            <xsl:with-param name="content-start" select="$content-start"/>
                                            <xsl:with-param name="content-end" select="$content-end"/>
                                            <xsl:with-param name="content-type" select="$content-type"/>
                                            <xsl:with-param name="lb" select="$lb"/>
                                            <xsl:with-param name="wit" select="$wit"/>
                                        </xsl:apply-templates>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:otherwise>
                </xsl:choose>
            </h3>
        </xsl:if>
        <xsl:if test="parent::tei:div[@type = 'poem']">
            <h4>
                <xsl:choose>
                    <xsl:when test="if ($content-end='') then (preceding::tei:pb[1][@xml:id=$content-start]) else (preceding::tei:pb[1][@xml:id=$content-start]  and following::tei:pb[1][@xml:id=$content-end])">
                        <xsl:apply-templates>
                            <xsl:with-param name="type" select="$type"/>
                            <xsl:with-param name="mode" select="$mode"/>
                            <xsl:with-param name="content-start" select="$content-start"/>
                            <xsl:with-param name="content-end" select="$content-end"/>
                            <xsl:with-param name="content-type" select="$content-type"/>
                            <xsl:with-param name="lb" select="$lb"/>
                            <xsl:with-param name="wit" select="$wit"/>
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:choose>
                            <xsl:when test="descendant::tei:pb[@xml:id=$content-start] or descendant::tei:pb[@xml:id=$content-end]">
                                <xsl:apply-templates>
                                    <xsl:with-param name="type" select="$type"/>
                                    <xsl:with-param name="mode" select="$mode"/>
                                    <xsl:with-param name="content-start" select="$content-start"/>
                                    <xsl:with-param name="content-end" select="$content-end"/>
                                    <xsl:with-param name="content-type" select="$content-type"/>
                                    <xsl:with-param name="lb" select="$lb"/>
                                    <xsl:with-param name="wit" select="$wit"/>
                                </xsl:apply-templates>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:otherwise>
                </xsl:choose>
            </h4>
        </xsl:if>
        <!-- ostalih child div (trenutno?) ni -->
    </xsl:template>
    
    <xsl:template match="node()" mode="besedilo" xml:space="preserve">
        <xsl:copy>
            <xsl:apply-templates select="node()" mode="besedilo"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- TODO: dodaj še odstavke in podobno -->
    
    <xsl:template match="tei:ab">
        <xsl:param name="type"/>
        <xsl:param name="mode"/>
        <xsl:param name="content-start"/>
        <xsl:param name="content-end"/>
        <xsl:param name="content-type"/>
        <xsl:param name="lb"/>
        <xsl:param name="wit"/>
        <xsl:if test="$type='page'">
            <xsl:if test="if ($content-end='') then (preceding::tei:pb[1][@xml:id=$content-start]) else (preceding::tei:pb[1][@xml:id=$content-start]  and following::tei:pb[1][@xml:id=$content-end])">
                <p>
                    <xsl:apply-templates>
                        <xsl:with-param name="type" select="$type"/>
                        <xsl:with-param name="mode" select="$mode"/>
                        <xsl:with-param name="content-start" select="$content-start"/>
                        <xsl:with-param name="content-end" select="$content-end"/>
                        <xsl:with-param name="content-type" select="$content-type"/>
                        <xsl:with-param name="lb" select="$lb"/>
                        <xsl:with-param name="wit" select="$wit"/>
                    </xsl:apply-templates>
                </p>
            </xsl:if>
        </xsl:if>
        <xsl:if test="$type='variant'">
            <p>
                <xsl:apply-templates>
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="mode" select="$mode"/>
                    <xsl:with-param name="content-start" select="$content-start"/>
                    <xsl:with-param name="content-end" select="$content-end"/>
                    <xsl:with-param name="content-type" select="$content-type"/>
                    <xsl:with-param name="lb" select="$lb"/>
                    <xsl:with-param name="wit" select="$wit"/>
                </xsl:apply-templates>
            </p>
        </xsl:if>
    </xsl:template>
    
    <!-- closer sem naredil isto kot ab -->
    <xsl:template match="tei:closer">
        <xsl:param name="type"/>
        <xsl:param name="mode"/>
        <xsl:param name="content-start"/>
        <xsl:param name="content-end"/>
        <xsl:param name="content-type"/>
        <xsl:param name="lb"/>
        <xsl:param name="wit"/>
        <xsl:if test="$type='page'">
            <xsl:if test="if ($content-end='') then (preceding::tei:pb[1][@xml:id=$content-start]) else (preceding::tei:pb[1][@xml:id=$content-start]  and following::tei:pb[1][@xml:id=$content-end])">
                <p>
                    <xsl:apply-templates>
                        <xsl:with-param name="type" select="$type"/>
                        <xsl:with-param name="mode" select="$mode"/>
                        <xsl:with-param name="content-start" select="$content-start"/>
                        <xsl:with-param name="content-end" select="$content-end"/>
                        <xsl:with-param name="content-type" select="$content-type"/>
                        <xsl:with-param name="lb" select="$lb"/>
                        <xsl:with-param name="wit" select="$wit"/>
                    </xsl:apply-templates>
                </p>
            </xsl:if>
        </xsl:if>
        <xsl:if test="$type='variant'">
            <p>
                <xsl:apply-templates>
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="mode" select="$mode"/>
                    <xsl:with-param name="content-start" select="$content-start"/>
                    <xsl:with-param name="content-end" select="$content-end"/>
                    <xsl:with-param name="content-type" select="$content-type"/>
                    <xsl:with-param name="lb" select="$lb"/>
                    <xsl:with-param name="wit" select="$wit"/>
                </xsl:apply-templates>
            </p>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="tei:lg">
        <xsl:param name="type"/>
        <xsl:param name="mode"/>
        <xsl:param name="content-start"/>
        <xsl:param name="content-end"/>
        <xsl:param name="content-type"/>
        <xsl:param name="lb"/>
        <xsl:param name="wit"/>
        <xsl:if test="$type='page'">
            <xsl:choose>
                <xsl:when test="if ($content-end='') then (preceding::tei:pb[1][@xml:id=$content-start]) else (preceding::tei:pb[1][@xml:id=$content-start]  and following::tei:pb[1][@xml:id=$content-end])">
                    <blockquote>
                        <xsl:if test="@rend='linenumber' and $lb='1'">
                            <span class="numberParagraph">
                                <xsl:value-of select="@n"/>
                            </span>
                        </xsl:if>
                        <xsl:apply-templates>
                            <xsl:with-param name="type" select="$type"/>
                            <xsl:with-param name="mode" select="$mode"/>
                            <xsl:with-param name="content-start" select="$content-start"/>
                            <xsl:with-param name="content-end" select="$content-end"/>
                            <xsl:with-param name="content-type" select="$content-type"/>
                            <xsl:with-param name="lb" select="$lb"/>
                            <xsl:with-param name="wit" select="$wit"/>
                        </xsl:apply-templates>
                    </blockquote>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:choose>
                        <xsl:when test="descendant::tei:pb[@xml:id=$content-start] or descendant::tei:pb[@xml:id=$content-end]">
                            <xsl:apply-templates>
                                <xsl:with-param name="type" select="$type"/>
                                <xsl:with-param name="mode" select="$mode"/>
                                <xsl:with-param name="content-start" select="$content-start"/>
                                <xsl:with-param name="content-end" select="$content-end"/>
                                <xsl:with-param name="content-type" select="$content-type"/>
                                <xsl:with-param name="lb" select="$lb"/>
                                <xsl:with-param name="wit" select="$wit"/>
                            </xsl:apply-templates>
                        </xsl:when>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <xsl:if test="$type='variant'">
            <blockquote>
                <xsl:if test="@rend='linenumber' and $lb='1'">
                    <span class="numberParagraph">
                        <xsl:value-of select="@n"/>
                    </span>
                </xsl:if>
                <xsl:apply-templates>
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="mode" select="$mode"/>
                    <xsl:with-param name="content-start" select="$content-start"/>
                    <xsl:with-param name="content-end" select="$content-end"/>
                    <xsl:with-param name="content-type" select="$content-type"/>
                    <xsl:with-param name="lb" select="$lb"/>
                    <xsl:with-param name="wit" select="$wit"/>
                </xsl:apply-templates>
            </blockquote>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="tei:lg/tei:l">
        <xsl:param name="type"/>
        <xsl:param name="mode"/>
        <xsl:param name="content-start"/>
        <xsl:param name="content-end"/>
        <xsl:param name="content-type"/>
        <xsl:param name="lb"/>
        <xsl:param name="wit"/>
        <xsl:if test="$type='page'">
            <xsl:if test="if ($content-end='') then (preceding::tei:pb[1][@xml:id=$content-start]) else (preceding::tei:pb[1][@xml:id=$content-start]  and following::tei:pb[1][@xml:id=$content-end])">
                <xsl:if test="@rend='linenumber' and $lb='1'">
                    <span class="numberParagraph">
                        <xsl:value-of select="@n"/>
                    </span>
                </xsl:if>
                <xsl:apply-templates>
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="mode" select="$mode"/>
                    <xsl:with-param name="content-start" select="$content-start"/>
                    <xsl:with-param name="content-end" select="$content-end"/>
                    <xsl:with-param name="content-type" select="$content-type"/>
                    <xsl:with-param name="lb" select="$lb"/>
                    <xsl:with-param name="wit" select="$wit"/>
                </xsl:apply-templates>
                <xsl:choose>
                    <xsl:when test="$lb='1'">
                        <xsl:if test="position() != last()">
                            <br/>
                        </xsl:if>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:if test="position() != last()">
                            <span class="emph"> | </span>
                        </xsl:if>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
        </xsl:if>
        <xsl:if test="$type='variant'">
            <xsl:if test="@rend='linenumber' and $lb='1'">
                <span class="numberParagraph">
                    <xsl:value-of select="@n"/>
                </span>
            </xsl:if>
            <xsl:apply-templates>
                <xsl:with-param name="type" select="$type"/>
                <xsl:with-param name="mode" select="$mode"/>
                <xsl:with-param name="content-start" select="$content-start"/>
                <xsl:with-param name="content-end" select="$content-end"/>
                <xsl:with-param name="content-type" select="$content-type"/>
                <xsl:with-param name="lb" select="$lb"/>
                <xsl:with-param name="wit" select="$wit"/>
            </xsl:apply-templates>
            <xsl:choose>
                <xsl:when test="$lb='1'">
                    <xsl:if test="position() != last()">
                        <br/>
                    </xsl:if>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:if test="position() != last()">
                        <span class="emph"> | </span>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="tei:label">
        <xsl:param name="type"/>
        <xsl:param name="mode"/>
        <xsl:param name="content-start"/>
        <xsl:param name="content-end"/>
        <xsl:param name="content-type"/>
        <xsl:param name="lb"/>
        <xsl:param name="wit"/>
        <xsl:if test="$type='page'">
            <xsl:if test="if ($content-end='') then (preceding::tei:pb[1][@xml:id=$content-start]) else (preceding::tei:pb[1][@xml:id=$content-start]  and following::tei:pb[1][@xml:id=$content-end])">
                <div class="{if (@rend) then ('text'|| @rend) else 'padding'}">
                    <xsl:apply-templates>
                        <xsl:with-param name="type" select="$type"/>
                        <xsl:with-param name="mode" select="$mode"/>
                        <xsl:with-param name="content-start" select="$content-start"/>
                        <xsl:with-param name="content-end" select="$content-end"/>
                        <xsl:with-param name="content-type" select="$content-type"/>
                        <xsl:with-param name="lb" select="$lb"/>
                        <xsl:with-param name="wit" select="$wit"/>
                    </xsl:apply-templates>
                </div>
            </xsl:if>
        </xsl:if>
        <xsl:if test="$type='variant'">
            <div class="{if (@rend) then ('text-'|| @rend) else 'padding'}">
                <xsl:apply-templates>
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="mode" select="$mode"/>
                    <xsl:with-param name="content-start" select="$content-start"/>
                    <xsl:with-param name="content-end" select="$content-end"/>
                    <xsl:with-param name="content-type" select="$content-type"/>
                    <xsl:with-param name="lb" select="$lb"/>
                    <xsl:with-param name="wit" select="$wit"/>
                </xsl:apply-templates>
            </div>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="tei:lb">
        <xsl:param name="type"/>
        <xsl:param name="mode"/>
        <xsl:param name="content-start"/>
        <xsl:param name="content-end"/>
        <xsl:param name="content-type"/>
        <xsl:param name="lb"/>
        <xsl:param name="wit"/>
        <xsl:if test="$type='page'">
            <xsl:if test="if ($content-end='') then (preceding::tei:pb[1][@xml:id=$content-start]) else (preceding::tei:pb[1][@xml:id=$content-start]  and following::tei:pb[1][@xml:id=$content-end])">
                <xsl:call-template name="lb">
                    <xsl:with-param name="lb" select="$lb"/>
                </xsl:call-template>
            </xsl:if>
        </xsl:if>
        <xsl:if test="$type='variant'">
            <xsl:call-template name="lb">
                <xsl:with-param name="lb" select="$lb"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="lb">
        <xsl:param name="lb"/>
        <xsl:choose>
            <xsl:when test="@break = 'no'">
                <span class="emph"> | </span>
            </xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="$lb='1'">
                        <br/>
                    </xsl:when>
                    <xsl:otherwise>
                        <span class="emph"> | </span>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="tei:hi">
        <xsl:param name="type"/>
        <xsl:param name="mode"/>
        <xsl:param name="content-start"/>
        <xsl:param name="content-end"/>
        <xsl:param name="content-type"/>
        <xsl:param name="lb"/>
        <xsl:param name="wit"/>
        <span>
            <xsl:choose>
                <xsl:when test="@rend='bold'">
                    <xsl:attribute name="style">font-weight:bold;</xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="class">hi</xsl:attribute>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates>
                <xsl:with-param name="type" select="$type"/>
                <xsl:with-param name="mode" select="$mode"/>
                <xsl:with-param name="content-start" select="$content-start"/>
                <xsl:with-param name="content-end" select="$content-end"/>
                <xsl:with-param name="content-type" select="$content-type"/>
                <xsl:with-param name="lb" select="$lb"/>
                <xsl:with-param name="wit" select="$wit"/>
            </xsl:apply-templates>
        </span>
    </xsl:template>
    
    <xsl:template match="tei:note">
        <xsl:param name="type"/>
        <xsl:param name="mode"/>
        <xsl:param name="content-start"/>
        <xsl:param name="content-end"/>
        <xsl:param name="content-type"/>
        <xsl:param name="lb"/>
        <xsl:param name="wit"/>
        <sup>
            <span class="emph term" data-explain="{@xml:id}">
                <xsl:value-of select="concat(' [',@n,']')"/>
            </span>
        </sup>
        <div id="{@xml:id}" class="explain" style="display: none;">
            <xsl:text>urednikova opomba: </xsl:text>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    
    <xsl:template match="tei:handShift">
        <xsl:param name="type"/>
        <xsl:param name="mode"/>
        <xsl:param name="content-start"/>
        <xsl:param name="content-end"/>
        <xsl:param name="content-type"/>
        <xsl:param name="lb"/>
        <xsl:param name="wit"/>
        <xsl:variable name="id" select="substring-after(@new,'#')"/>
        <span class="emph term" data-explain="{@xml:id}">→</span>
        <div id="{@xml:id}" class="explain" style="display: none;">
            <xsl:text>sprememba roke → opomba o roki:</xsl:text>
            <xsl:for-each select="ancestor::tei:TEI/tei:teiHeader/tei:profileDesc/tei:handNotes/tei:handNote[@xml:id=$id]">
                <ul>
                    <li>pisar: <xsl:value-of select="@scribe || ' ' ||."/></li>
                </ul>
            </xsl:for-each>
        </div>
    </xsl:template>
    
    <xsl:template match="tei:supplied">
        <xsl:param name="type"/>
        <xsl:param name="mode"/>
        <xsl:param name="content-start"/>
        <xsl:param name="content-end"/>
        <xsl:param name="content-type"/>
        <xsl:param name="lb"/>
        <xsl:param name="wit"/>
        <span class="emph term" data-explain="{@xml:id}">
            <xsl:apply-templates>
                <xsl:with-param name="type" select="$type"/>
                <xsl:with-param name="mode" select="$mode"/>
                <xsl:with-param name="content-start" select="$content-start"/>
                <xsl:with-param name="content-end" select="$content-end"/>
                <xsl:with-param name="content-type" select="$content-type"/>
                <xsl:with-param name="lb" select="$lb"/>
                <xsl:with-param name="wit" select="$wit"/>
            </xsl:apply-templates>
        </span>
        <div id="{@xml:id}" class="explain" style="display: none;">
            <xsl:text>vstavil urednik:</xsl:text>
            <xsl:if test="@reason | @resp">
                <ul>
                    <xsl:if test="@resp">
                        <!-- trenutno samo en urednik -->
                        <li>Nina Ditmajer</li>
                    </xsl:if>
                </ul>
            </xsl:if>
        </div>
    </xsl:template>
    
    <xsl:template match="tei:choice[tei:abbr and tei:expan]">
        <xsl:param name="type"/>
        <xsl:param name="mode"/>
        <xsl:param name="content-start"/>
        <xsl:param name="content-end"/>
        <xsl:param name="content-type"/>
        <xsl:param name="lb"/>
        <xsl:param name="wit"/>
        <xsl:if test="$content-type = 'dipl'">
            <span class="choice term" data-explain="{@xml:id}">
                <xsl:apply-templates select="tei:abbr">
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="mode" select="$mode"/>
                    <xsl:with-param name="content-start" select="$content-start"/>
                    <xsl:with-param name="content-end" select="$content-end"/>
                    <xsl:with-param name="content-type" select="$content-type"/>
                    <xsl:with-param name="lb" select="$lb"/>
                    <xsl:with-param name="wit" select="$wit"/>
                </xsl:apply-templates>
            </span>
            <sup class="term-sup" data-explain="{@xml:id}">
                <xsl:value-of select="concat('[c', tokenize(@xml:id,'-')[2],']')"/>
            </sup>
            <div id="{@xml:id}" class="explain" style="display: none;">
                <xsl:text>okrajšava  &#x2192; razvezava: </xsl:text>
                <xsl:apply-templates select="tei:expan">
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="mode" select="$mode"/>
                    <xsl:with-param name="content-start" select="$content-start"/>
                    <xsl:with-param name="content-end" select="$content-end"/>
                    <xsl:with-param name="content-type" select="$content-type"/>
                    <xsl:with-param name="lb" select="$lb"/>
                    <xsl:with-param name="wit" select="$wit"/>
                </xsl:apply-templates>
            </div>
        </xsl:if>
        <xsl:if test="$content-type = 'crit'">
            <span class="choice term" data-explain="{@xml:id}">
                <xsl:apply-templates select="tei:expan">
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="mode" select="$mode"/>
                    <xsl:with-param name="content-start" select="$content-start"/>
                    <xsl:with-param name="content-end" select="$content-end"/>
                    <xsl:with-param name="content-type" select="$content-type"/>
                    <xsl:with-param name="lb" select="$lb"/>
                    <xsl:with-param name="wit" select="$wit"/>
                </xsl:apply-templates>
            </span>
            <sup class="term-sup" data-explain="{@xml:id}">
                <xsl:value-of select="concat('[c', tokenize(@xml:id,'-')[2],']')"/>
            </sup>
            <div id="{@xml:id}" class="explain" style="display: none;">
                <xsl:text>razvezava &#x2190; okrajšava: </xsl:text>
                <xsl:apply-templates select="tei:abbr">
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="mode" select="$mode"/>
                    <xsl:with-param name="content-start" select="$content-start"/>
                    <xsl:with-param name="content-end" select="$content-end"/>
                    <xsl:with-param name="content-type" select="$content-type"/>
                    <xsl:with-param name="lb" select="$lb"/>
                    <xsl:with-param name="wit" select="$wit"/>
                </xsl:apply-templates>
            </div>
        </xsl:if>
    </xsl:template> 
    
    <xsl:template match="tei:choice[tei:sic and tei:corr]">
        <xsl:param name="type"/>
        <xsl:param name="mode"/>
        <xsl:param name="content-start"/>
        <xsl:param name="content-end"/>
        <xsl:param name="content-type"/>
        <xsl:param name="lb"/>
        <xsl:param name="wit"/>
        <xsl:if test="$content-type = 'dipl'">
            <span class="choice term" data-explain="{@xml:id}">
                <xsl:apply-templates select="tei:sic">
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="mode" select="$mode"/>
                    <xsl:with-param name="content-start" select="$content-start"/>
                    <xsl:with-param name="content-end" select="$content-end"/>
                    <xsl:with-param name="content-type" select="$content-type"/>
                    <xsl:with-param name="lb" select="$lb"/>
                    <xsl:with-param name="wit" select="$wit"/>
                </xsl:apply-templates>
            </span>
            <sup class="term-sup" data-explain="{@xml:id}">
                <xsl:value-of select="concat('[c', tokenize(@xml:id,'-')[2],']')"/>
            </sup>
            <div id="{@xml:id}" class="explain" style="display: none;">
                <xsl:text>napaka &#x2192; uredniški popravek: </xsl:text>
                <xsl:apply-templates select="tei:corr">
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="mode" select="$mode"/>
                    <xsl:with-param name="content-start" select="$content-start"/>
                    <xsl:with-param name="content-end" select="$content-end"/>
                    <xsl:with-param name="content-type" select="$content-type"/>
                    <xsl:with-param name="lb" select="$lb"/>
                    <xsl:with-param name="wit" select="$wit"/>
                </xsl:apply-templates>
            </div>
        </xsl:if>
        <xsl:if test="$content-type = 'crit'">
            <span class="choice term" data-explain="{@xml:id}">
                <xsl:apply-templates select="tei:corr">
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="mode" select="$mode"/>
                    <xsl:with-param name="content-start" select="$content-start"/>
                    <xsl:with-param name="content-end" select="$content-end"/>
                    <xsl:with-param name="content-type" select="$content-type"/>
                    <xsl:with-param name="lb" select="$lb"/>
                    <xsl:with-param name="wit" select="$wit"/>
                </xsl:apply-templates>
            </span>
            <sup class="term-sup" data-explain="{@xml:id}">
                <xsl:value-of select="concat('[c', tokenize(@xml:id,'-')[2],']')"/>
            </sup>
            <div id="{@xml:id}" class="explain" style="display: none;">
                <xsl:text>uredniški popravek &#x2190; napaka: </xsl:text>
                <xsl:apply-templates select="tei:sic">
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="mode" select="$mode"/>
                    <xsl:with-param name="content-start" select="$content-start"/>
                    <xsl:with-param name="content-end" select="$content-end"/>
                    <xsl:with-param name="content-type" select="$content-type"/>
                    <xsl:with-param name="lb" select="$lb"/>
                    <xsl:with-param name="wit" select="$wit"/>
                </xsl:apply-templates>
            </div>
        </xsl:if>
    </xsl:template>
    
    <!-- dodal še to choice možnost -->
    <xsl:template match="tei:choice[tei:orig and tei:reg]">
        <xsl:param name="type"/>
        <xsl:param name="mode"/>
        <xsl:param name="content-start"/>
        <xsl:param name="content-end"/>
        <xsl:param name="content-type"/>
        <xsl:param name="lb"/>
        <xsl:param name="wit"/>
        <xsl:if test="$content-type = 'dipl'">
            <span class="choice term" data-explain="{@xml:id}">
                <xsl:apply-templates select="tei:orig">
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="mode" select="$mode"/>
                    <xsl:with-param name="content-start" select="$content-start"/>
                    <xsl:with-param name="content-end" select="$content-end"/>
                    <xsl:with-param name="content-type" select="$content-type"/>
                    <xsl:with-param name="lb" select="$lb"/>
                    <xsl:with-param name="wit" select="$wit"/>
                </xsl:apply-templates>
            </span>
            <sup class="term-sup" data-explain="{@xml:id}">
                <xsl:value-of select="concat('[c', tokenize(@xml:id,'-')[2],']')"/>
            </sup>
            <div id="{@xml:id}" class="explain" style="display: none;">
                <xsl:text>izvorna oblika &#x2192; regularizirano: </xsl:text>
                <xsl:apply-templates select="tei:reg">
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="mode" select="$mode"/>
                    <xsl:with-param name="content-start" select="$content-start"/>
                    <xsl:with-param name="content-end" select="$content-end"/>
                    <xsl:with-param name="content-type" select="$content-type"/>
                    <xsl:with-param name="lb" select="$lb"/>
                    <xsl:with-param name="wit" select="$wit"/>
                </xsl:apply-templates>
            </div>
        </xsl:if>
        <xsl:if test="$content-type = 'crit'">
            <span class="choice term" data-explain="{@xml:id}">
                <xsl:apply-templates select="tei:reg">
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="mode" select="$mode"/>
                    <xsl:with-param name="content-start" select="$content-start"/>
                    <xsl:with-param name="content-end" select="$content-end"/>
                    <xsl:with-param name="content-type" select="$content-type"/>
                    <xsl:with-param name="lb" select="$lb"/>
                    <xsl:with-param name="wit" select="$wit"/>
                </xsl:apply-templates>
            </span>
            <sup class="term-sup" data-explain="{@xml:id}">
                <xsl:value-of select="concat('[c', tokenize(@xml:id,'-')[2],']')"/>
            </sup>
            <div id="{@xml:id}" class="explain" style="display: none;">
                <xsl:text>regularizirano &#x2190; izvorna oblika: </xsl:text>
                <xsl:apply-templates select="tei:orig">
                    <xsl:with-param name="type" select="$type"/>
                    <xsl:with-param name="mode" select="$mode"/>
                    <xsl:with-param name="content-start" select="$content-start"/>
                    <xsl:with-param name="content-end" select="$content-end"/>
                    <xsl:with-param name="content-type" select="$content-type"/>
                    <xsl:with-param name="lb" select="$lb"/>
                    <xsl:with-param name="wit" select="$wit"/>
                </xsl:apply-templates>
            </div>
        </xsl:if>
    </xsl:template>
    
    <!-- procesiram še choice child elemente -->
    <xsl:template match="tei:abbr | tei:expan | tei:sic | tei:corr | tei:orig | tei:reg">
        <xsl:param name="type"/>
        <xsl:param name="mode"/>
        <xsl:param name="content-start"/>
        <xsl:param name="content-end"/>
        <xsl:param name="content-type"/>
        <xsl:param name="lb"/>
        <xsl:param name="wit"/>
        <xsl:apply-templates>
            <xsl:with-param name="type" select="$type"/>
            <xsl:with-param name="mode" select="$mode"/>
            <xsl:with-param name="content-start" select="$content-start"/>
            <xsl:with-param name="content-end" select="$content-end"/>
            <xsl:with-param name="content-type" select="$content-type"/>
            <xsl:with-param name="lb" select="$lb"/>
            <xsl:with-param name="wit" select="$wit"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <!-- od tu naprej sem iz Kapelskega prevzel samo izbrane, za katere vem, da so tudi v Foglarjevemu -->
    
    <xsl:template match="tei:del">
        <xsl:param name="type"/>
        <xsl:param name="mode"/>
        <xsl:param name="content-start"/>
        <xsl:param name="content-end"/>
        <xsl:param name="content-type"/>
        <xsl:param name="lb"/>
        <xsl:param name="wit"/>
        <del>
            <xsl:apply-templates>
                <xsl:with-param name="type" select="$type"/>
                <xsl:with-param name="mode" select="$mode"/>
                <xsl:with-param name="content-start" select="$content-start"/>
                <xsl:with-param name="content-end" select="$content-end"/>
                <xsl:with-param name="content-type" select="$content-type"/>
                <xsl:with-param name="lb" select="$lb"/>
                <xsl:with-param name="wit" select="$wit"/>
            </xsl:apply-templates>
        </del>
    </xsl:template>
    
    <!-- nisem uredil še vseh možnih vrednosti za atribut place: margin-right, inline -->
    <xsl:template match="tei:add">
        <xsl:param name="type"/>
        <xsl:param name="mode"/>
        <xsl:param name="content-start"/>
        <xsl:param name="content-end"/>
        <xsl:param name="content-type"/>
        <xsl:param name="lb"/>
        <xsl:param name="wit"/>
        <xsl:variable name="place" select="if (@place='above') then 'sup' else (if (@place='below') then 'sub' else '')"/>
        <xsl:choose>
            <xsl:when test="string-length($place) gt 0">
                <xsl:element name="{$place}">
                    <ins>
                        <xsl:apply-templates>
                            <xsl:with-param name="type" select="$type"/>
                            <xsl:with-param name="mode" select="$mode"/>
                            <xsl:with-param name="content-start" select="$content-start"/>
                            <xsl:with-param name="content-end" select="$content-end"/>
                            <xsl:with-param name="content-type" select="$content-type"/>
                            <xsl:with-param name="lb" select="$lb"/>
                            <xsl:with-param name="wit" select="$wit"/>
                        </xsl:apply-templates>
                    </ins>
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <ins>
                    <xsl:apply-templates>
                        <xsl:with-param name="type" select="$type"/>
                        <xsl:with-param name="mode" select="$mode"/>
                        <xsl:with-param name="content-start" select="$content-start"/>
                        <xsl:with-param name="content-end" select="$content-end"/>
                        <xsl:with-param name="content-type" select="$content-type"/>
                        <xsl:with-param name="lb" select="$lb"/>
                        <xsl:with-param name="wit" select="$wit"/>
                    </xsl:apply-templates>
                </ins>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- nisem še uredil atributa reason -->
    <xsl:template match="tei:unclear">
        <xsl:param name="type"/>
        <xsl:param name="mode"/>
        <xsl:param name="content-start"/>
        <xsl:param name="content-end"/>
        <xsl:param name="content-type"/>
        <xsl:param name="lb"/>
        <xsl:param name="wit"/>
        <span class="unclear">
            <xsl:apply-templates>
                <xsl:with-param name="type" select="$type"/>
                <xsl:with-param name="mode" select="$mode"/>
                <xsl:with-param name="content-start" select="$content-start"/>
                <xsl:with-param name="content-end" select="$content-end"/>
                <xsl:with-param name="content-type" select="$content-type"/>
                <xsl:with-param name="lb" select="$lb"/>
                <xsl:with-param name="wit" select="$wit"/>
            </xsl:apply-templates>
        </span>
    </xsl:template>
    
    <xsl:template match="tei:gap">
        <span class="emph term" data-explain="{@xml:id}">
            <xsl:text>[...]</xsl:text>
        </span>
        <div id="{@xml:id}" class="explain" style="display: none;">
            <xsl:text>vrzel:</xsl:text>
            <ul>
                <xsl:if test="@unit">
                    <li>
                        <xsl:text>enota: </xsl:text>
                        <xsl:if test="@unit='lines'">vrstice</xsl:if>
                        <xsl:if test="@quantity">
                            <xsl:text>; količina: </xsl:text>
                            <xsl:value-of select="@quantity"/>
                        </xsl:if>
                    </li>
                </xsl:if>
            </ul>
        </div>
    </xsl:template>
    
    
</xsl:stylesheet>