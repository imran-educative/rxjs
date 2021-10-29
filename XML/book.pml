<?xml version="1.0" encoding="UTF-8"?> <!-- -*- xml -*- -->
<!DOCTYPE book SYSTEM "local/xml/markup.dtd">

<book xmlns:pml="http://pragprog.com/ns/pml">

  <pml:include file="../bookinfo"/>

  <frontmatter>
    <pml:ignore file="Changes"/>
    <pml:include file="Praise"/>
<extract id="ex.1" title="intro"/>
    <pml:include file="Introduction"/>
<extract idref="ex.1"/>
  </frontmatter>

<!-- https://docs.google.com/spreadsheets/d/1ZR2CcWA5CBhgZFTgs0mKB3RVkT4pyEZB21czHTGcssc/edit?usp=sharing -->

  <mainmatter>
    <pml:include file="creatingObservables"/>
    <pml:include file="manipulatingStreams"/>
    <pml:include file="managingAsync"/>
    <pml:include file="advancedAsync"/>
    <pml:include file="multiplexingObservables"/>

    <pml:include file="ng2ajax"/>
    <pml:include file="ng2ReactiveForms"/>
    <pml:include file="ng2events"/>

    <pml:include file="canvas"/>

    <pml:ignore file="lettableOperators"/>

    <pml:ignore file="Bibliography"/>
    <index />
  </mainmatter>

  <pml:include file="backmatter" />
</book>
