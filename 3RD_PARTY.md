# Third-Party Copyright and License Information

This document provides copyright and license information for third-party software and files used in "I, Voyager" software distributed from https://www.ivoyager.dev and https://github.com/ivoyager.

The master version of this file is maintained [here](https://github.com/ivoyager/ivoyager_core/blob/master/3RD_PARTY.md).

**Contact:** Charlie Whitfield (mail@ivoyager.dev)

---

## Software

### Godot Engine

I, Voyager software distributions run on the [Godot Engine](https://godotengine.org/) and were developed using the Godot Engine editor. Licencing information for files used in Godot Engine can be found [here](https://github.com/godotengine/godot/blob/master/COPYRIGHT.txt).

- **Copyright:** 2014-present, Godot Engine [contributors](https://github.com/godotengine/godot/blob/master/AUTHORS.md); 2007-2014, Juan Linietsky, Ariel Manzur  
- **License:** [MIT](#mit)


## Files

These files are located in subdirectories of `/addons/ivoyager_assets/` in project development builds and distributed from [this repository](https://github.com/ivoyager/asset_downloads), except where noted otherwise. Many of the images here were modified by Charlie Whitfield.


### World maps by Björn Jónsson (from Planetary Society)

Files were downloaded from https://www.planetary.org/space-images, and reduced in size from much larger file images.

Subdirectory `/2d_bodies/` contains derived images (flat projections of wrapped globes).

- **Files:**
  - `/maps/Europa.albedo.8192.jpg`
  - `/maps/Jupiter.albedo.8192.jpg`
- **Copyright:** Björn Jónsson
- **License:** [CC-BY-3.0](#cc-by-30)


### World maps by Björn Jónsson (from bjj.mmedia.is)

Files were downloaded from https://bjj.mmedia.is/data/planetary_maps.html.

Neptune color was significantly adjusted by Charlie Whitfield to match published images [here](https://academic.oup.com/mnras/article/527/4/11521/7511973).

Subdirectory `/2d_bodies/` contains derived images (flat projections of wrapped globes).

- **Files:**
  - `/maps/Callisto.albedo.1800.jpg`
  - `/maps/Ganymede.albedo.1800.jpg`
  - `/maps/Io.albedo.3600.jpg`
  - `/maps/Neptune.albedo.4096.jpg`
  - `/maps/Rhea.albedo.1800.jpg`
  - `/maps/Saturn.albedo.2880.jpg`
  - `/maps/Venus.albedo.4096.jpg`
- **Copyright:** Björn Jónsson
- **License:** See full website notice [here](https://bjj.mmedia.is/data/planetary_maps.html). Excerpt:
```
All the planetary maps available on these pages are publicly available.
You do not need a special permission to use them but if you do then
please mention their origin in your work, e.g. "created by Björn
Jónsson" or something equivalent.
```


### Sun map by James Hastings-Trew 

File downloaded from https://planetpixelemporium.com/sun.html.

Subdirectory `/2d_bodies/` contains derived images (flat projections of wrapped globes).

- **File:** `/maps/Sun.emission.4096.jpg`  
- **Copyright:** James Hastings-Trew
- **License:** See full website notice [here](https://planetpixelemporium.com/planets.html). Excerpt:
```
The maps are free to download and use as source material or resource in
artwork or rendering (CGI or real time) in any kind of project - personal,
commercial, broadcast, or display. You are not free to redistribute the
maps "as is" in any medium - online, CD, for sale, etc. where the primary
intent is to distribute the maps themselves and not the result of using
the maps, without my permission.
```


### NASA images and models

Most NASA images and models are in the public domain. Use is governed by [NASA Images and Media Usage Guidelines](https://www.nasa.gov/nasa-brand-center/images-and-media/).

Many world maps were modified by Charlie Whitfield. These modifications include substantial color adjustments to Mercury, Mars, Ceres and Uranus. Grid lines were added to unimaged areas of the moons of Uranus and Neptune.

Starmaps were downloaded from https://svs.gsfc.nasa.gov/4851/ ("Deep Star Maps 2020"). Some image processing was applied by Charlie Whitfield.

All 3D models were downloaded from https://science.nasa.gov/3d-resources/. Model subdirectories each contain the downloaded file (usually *.glb extension) and files extracted from the model by Godot's importer.

Subdirectory `/2d_bodies/` contains derived images (flat projections of wrapped globes and 3D models).

- **Files:**
  - `/maps/Ariel.albedo.2048.jpg`
  - `/maps/Ceres.albedo.4096.jpg`
  - `/maps/Charon.albedo.4096.jpg`
  - `/maps/Dione.albedo.4096.jpg`
  - `/maps/Earth.albedo.8192.jpg`
  - `/maps/Enceladus.albedo.4096.jpg`
  - `/maps/Iapetus.albedo.4096.jpg`
  - `/maps/Mars.albedo.4096.jpg`
  - `/maps/Mercury.albedo.4096.jpg`
  - `/maps/Miranda.albedo.2048.jpg`
  - `/maps/Moon.albedo.4096.jpg`
  - `/maps/Oberon.albedo.2048.jpg`
  - `/maps/Phoebe.albedo.2048.jpg`
  - `/maps/Pluto.albedo.4096.jpg`
  - `/maps/Tethys.albedo.4096.jpg`
  - `/maps/Titania.albedo.2048.jpg`
  - `/maps/Triton.albedo.4096.jpg`
  - `/maps/Umbriel.albedo.2048.jpg`
  - `/starmaps/starmap_8k.jpg`
  - `/starmaps/starmap_16k.jpg`
  - `pale_blue_dot.png` is distributed in the [Project Template repository](https://github.com/ivoyager/project_template).
  - `pale_blue_dot_453x614.jpg` is distributed in web-based deployments of the [Planetarium app](https://www.ivoyager.dev/planetarium/).
- **Model subdirectories:**
  - `/models/arrokoth/*`
  - `/models/bennu/*`
  - `/models/deimos/*`
  - `/models/eros/*`
  - `/models/hubble/*`
  - `/models/hyperion/*`
  - `/models/iss/*`
  - `/models/itokawa/*`
  - `/models/juno/*`
  - `/models/mimas/*`
  - `/models/phobos/*`
  - `/models/vesta/*`
- **Copyright:** Public Domain
- **License:** Public Domain; see [NASA Images and Media Usage Guidelines](https://www.nasa.gov/nasa-brand-center/images-and-media/).


### Blue noise by Christoph Peters

File downloaded from https://momentsingraphics.de/BlueNoise.html.

- **File:** `/noise/blue_noise_1024.png`
- **Copyright:** Public domain
- **License:** [CC0 1.0 Universal](#cc0-10)


### Roboto / Noto Sans Symbols fonts

The font file used is a merge of Roboto and Noto Sans Symbols, both [Google Fonts](https://fonts.google.com/).

- **File:** `/fonts/Roboto-NotoSansSymbols-merged.ttf`
- **Copyright:** Google LLC
- **License:** [SIL OPEN FONT LICENSE Version 1.1](#sil-open-font-licence-version-10)


---

## Licenses in Detail

### MIT

```
 Permission is hereby granted, free of charge, to any person obtaining
 a copy of this software and associated documentation files (the
 "Software"), to deal in the Software without restriction, including
 without limitation the rights to use, copy, modify, merge, publish,
 distribute, sublicense, and/or sell copies of the Software, and to
 permit persons to whom the Software is furnished to do so, subject to
 the following conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```

### CC-BY-3.0

[Creative Commons Attribution 3.0 Unported](http://creativecommons.org/licenses/by/3.0/)

```
 Creative Commons Attribution 3.0 Unported
 
 CREATIVE COMMONS CORPORATION IS NOT A LAW FIRM AND DOES NOT PROVIDE
 LEGAL SERVICES. DISTRIBUTION OF THIS LICENSE DOES NOT CREATE AN
 ATTORNEY-CLIENT RELATIONSHIP. CREATIVE COMMONS PROVIDES THIS INFORMATION
 ON AN "AS-IS" BASIS. CREATIVE COMMONS MAKES NO WARRANTIES REGARDING THE
 INFORMATION PROVIDED, AND DISCLAIMS LIABILITY FOR DAMAGES RESULTING FROM
 ITS USE.
 
 License
 
 THE WORK (AS DEFINED BELOW) IS PROVIDED UNDER THE TERMS OF THIS CREATIVE
 COMMONS PUBLIC LICENSE ("CCPL" OR "LICENSE"). THE WORK IS PROTECTED BY
 COPYRIGHT AND/OR OTHER APPLICABLE LAW. ANY USE OF THE WORK OTHER THAN AS
 AUTHORIZED UNDER THIS LICENSE OR COPYRIGHT LAW IS PROHIBITED.
 
 BY EXERCISING ANY RIGHTS TO THE WORK PROVIDED HERE, YOU ACCEPT AND AGREE
 TO BE BOUND BY THE TERMS OF THIS LICENSE. TO THE EXTENT THIS LICENSE MAY
 BE CONSIDERED TO BE A CONTRACT, THE LICENSOR GRANTS YOU THE RIGHTS
 CONTAINED HERE IN CONSIDERATION OF YOUR ACCEPTANCE OF SUCH TERMS AND
 CONDITIONS.
 
 1. Definitions
 
 a. "Adaptation" means a work based upon the Work, or upon the Work and
 other pre-existing works, such as a translation, adaptation, derivative
 work, arrangement of music or other alterations of a literary or
 artistic work, or phonogram or performance and includes cinematographic
 adaptations or any other form in which the Work may be recast,
 transformed, or adapted including in any form recognizably derived from
 the original, except that a work that constitutes a Collection will not
 be considered an Adaptation for the purpose of this License. For the
 avoidance of doubt, where the Work is a musical work, performance or
 phonogram, the synchronization of the Work in timed-relation with a
 moving image ("synching") will be considered an Adaptation for the
 purpose of this License.
 
 b. "Collection" means a collection of literary or artistic works, such
 as encyclopedias and anthologies, or performances, phonograms or
 broadcasts, or other works or subject matter other than works listed in
 Section 1(f) below, which, by reason of the selection and arrangement of
 their contents, constitute intellectual creations, in which the Work is
 included in its entirety in unmodified form along with one or more other
 contributions, each constituting separate and independent works in
 themselves, which together are assembled into a collective whole. A work
 that constitutes a Collection will not be considered an Adaptation (as
 defined above) for the purposes of this License.
 
 c.  "Distribute" means to make available to the public the original and
 copies of the Work or Adaptation, as appropriate, through sale or other
 transfer of ownership.
 
 d. "Licensor" means the individual, individuals, entity or entities that
 offer(s) the Work under the terms of this License.
 
 e. "Original Author" means, in the case of a literary or artistic work,
 the individual, individuals, entity or entities who created the Work or
 if no individual or entity can be identified, the publisher; and in
 addition (i) in the case of a performance the actors, singers,
 musicians, dancers, and other persons who act, sing, deliver, declaim,
 play in, interpret or otherwise perform literary or artistic works or
 expressions of folklore; (ii) in the case of a phonogram the producer
 being the person or legal entity who first fixes the sounds of a
 performance or other sounds; and, (iii) in the case of broadcasts, the
 organization that transmits the broadcast.
 
 f. "Work" means the literary and/or artistic work offered under the
 terms of this License including without limitation any production in the
 literary, scientific and artistic domain, whatever may be the mode or
 form of its expression including digital form, such as a book, pamphlet
 and other writing; a lecture, address, sermon or other work of the same
 nature; a dramatic or dramatico-musical work; a choreographic work or
 entertainment in dumb show; a musical composition with or without words;
 a cinematographic work to which are assimilated works expressed by a
 process analogous to cinematography; a work of drawing, painting,
 architecture, sculpture, engraving or lithography; a photographic work
 to which are assimilated works expressed by a process analogous to
 photography; a work of applied art; an illustration, map, plan, sketch
 or three-dimensional work relative to geography, topography,
 architecture or science; a performance; a broadcast; a phonogram; a
 compilation of data to the extent it is protected as a copyrightable
 work; or a work performed by a variety or circus performer to the extent
 it is not otherwise considered a literary or artistic work.
 
 g. "You" means an individual or entity exercising rights under this
 License who has not previously violated the terms of this License with
 respect to the Work, or who has received express permission from the
 Licensor to exercise rights under this License despite a previous
 violation.
 
 h. "Publicly Perform" means to perform public recitations of the Work
 and to communicate to the public those public recitations, by any means
 or process, including by wire or wireless means or public digital
 performances; to make available to the public Works in such a way that
 members of the public may access these Works from a place and at a place
 individually chosen by them; to perform the Work to the public by any
 means or process and the communication to the public of the performances
 of the Work, including by public digital performance; to broadcast and
 rebroadcast the Work by any means including signs, sounds or images.
 
 i. "Reproduce" means to make copies of the Work by any means including
 without limitation by sound or visual recordings and the right of
 fixation and reproducing fixations of the Work, including storage of a
 protected performance or phonogram in digital form or other electronic
 medium.
 
 2. Fair Dealing Rights. Nothing in this License is intended to reduce,
 limit, or restrict any uses free from copyright or rights arising from
 limitations or exceptions that are provided for in connection with the
 copyright protection under copyright law or other applicable laws.
 
 3. License Grant. Subject to the terms and conditions of this License,
 Licensor hereby grants You a worldwide, royalty-free, non-exclusive,
 perpetual (for the duration of the applicable copyright) license to
 exercise the rights in the Work as stated below:
 
 a. to Reproduce the Work, to incorporate the Work into one or more
 Collections, and to Reproduce the Work as incorporated in the
 Collections;
 
 b. to create and Reproduce Adaptations provided that any such
 Adaptation, including any translation in any medium, takes reasonable
 steps to clearly label, demarcate or otherwise identify that changes
 were made to the original Work. For example, a translation could be
 marked "The original work was translated from English to Spanish," or a
 modification could indicate "The original work has been modified.";
 
 c. to Distribute and Publicly Perform the Work including as incorporated
 in Collections; and,
 
 d. to Distribute and Publicly Perform Adaptations.
 
 e. For the avoidance of doubt:
 
 i. Non-waivable Compulsory License Schemes. In those jurisdictions in
 which the right to collect royalties through any statutory or compulsory
 licensing scheme cannot be waived, the Licensor reserves the exclusive
 right to collect such royalties for any exercise by You of the rights
 granted under this License;
 
 ii. Waivable Compulsory License Schemes. In those jurisdictions in which
 the right to collect royalties through any statutory or compulsory
 licensing scheme can be waived, the Licensor waives the exclusive right
 to collect such royalties for any exercise by You of the rights granted
 under this License; and,
 
 iii. Voluntary License Schemes. The Licensor waives the right to collect
 royalties, whether individually or, in the event that the Licensor is a
 member of a collecting society that administers voluntary licensing
 schemes, via that society, from any exercise by You of the rights
 granted under this License.
 
 The above rights may be exercised in all media and formats whether now
 known or hereafter devised. The above rights include the right to make
 such modifications as are technically necessary to exercise the rights
 in other media and formats. Subject to Section 8(f), all rights not
 expressly granted by Licensor are hereby reserved.
 
 4. Restrictions. The license granted in Section 3 above is expressly
 made subject to and limited by the following restrictions:
 
 a. You may Distribute or Publicly Perform the Work only under the terms
 of this License. You must include a copy of, or the Uniform Resource
 Identifier (URI) for, this License with every copy of the Work You
 Distribute or Publicly Perform. You may not offer or impose any terms on
 the Work that restrict the terms of this License or the ability of the
 recipient of the Work to exercise the rights granted to that recipient
 under the terms of the License. You may not sublicense the Work. You
 must keep intact all notices that refer to this License and to the
 disclaimer of warranties with every copy of the Work You Distribute or
 Publicly Perform. When You Distribute or Publicly Perform the Work, You
 may not impose any effective technological measures on the Work that
 restrict the ability of a recipient of the Work from You to exercise the
 rights granted to that recipient under the terms of the License. This
 Section 4(a) applies to the Work as incorporated in a Collection, but
 this does not require the Collection apart from the Work itself to be
 made subject to the terms of this License. If You create a Collection,
 upon notice from any Licensor You must, to the extent practicable,
 remove from the Collection any credit as required by Section 4(b), as
 requested. If You create an Adaptation, upon notice from any Licensor
 You must, to the extent practicable, remove from the Adaptation any
 credit as required by Section 4(b), as requested.
 
 b. If You Distribute, or Publicly Perform the Work or any Adaptations or
 Collections, You must, unless a request has been made pursuant to
 Section 4(a), keep intact all copyright notices for the Work and
 provide, reasonable to the medium or means You are utilizing: (i) the
 name of the Original Author (or pseudonym, if applicable) if supplied,
 and/or if the Original Author and/or Licensor designate another party or
 parties (e.g., a sponsor institute, publishing entity, journal) for
 attribution ("Attribution Parties") in Licensor's copyright notice,
 terms of service or by other reasonable means, the name of such party or
 parties; (ii) the title of the Work if supplied; (iii) to the extent
 reasonably practicable, the URI, if any, that Licensor specifies to be
 associated with the Work, unless such URI does not refer to the
 copyright notice or licensing information for the Work; and (iv) ,
 consistent with Section 3(b), in the case of an Adaptation, a credit
 identifying the use of the Work in the Adaptation (e.g., "French
 translation of the Work by Original Author," or "Screenplay based on
 original Work by Original Author"). The credit required by this Section
 4 (b) may be implemented in any reasonable manner; provided, however,
 that in the case of a Adaptation or Collection, at a minimum such credit
 will appear, if a credit for all contributing authors of the Adaptation
 or Collection appears, then as part of these credits and in a manner at
 least as prominent as the credits for the other contributing authors.
 For the avoidance of doubt, You may only use the credit required by this
 Section for the purpose of attribution in the manner set out above and,
 by exercising Your rights under this License, You may not implicitly or
 explicitly assert or imply any connection with, sponsorship or
 endorsement by the Original Author, Licensor and/or Attribution Parties,
 as appropriate, of You or Your use of the Work, without the separate,
 express prior written permission of the Original Author, Licensor and/or
 Attribution Parties.
 
 c. Except as otherwise agreed in writing by the Licensor or as may be
 otherwise permitted by applicable law, if You Reproduce, Distribute or
 Publicly Perform the Work either by itself or as part of any Adaptations
 or Collections, You must not distort, mutilate, modify or take other
 derogatory action in relation to the Work which would be prejudicial to
 the Original Author's honor or reputation. Licensor agrees that in those
 jurisdictions (e.g. Japan), in which any exercise of the right granted
 in Section 3(b) of this License (the right to make Adaptations) would be
 deemed to be a distortion, mutilation, modification or other derogatory
 action prejudicial to the Original Author's honor and reputation, the
 Licensor will waive or not assert, as appropriate, this Section, to the
 fullest extent permitted by the applicable national law, to enable You
 to reasonably exercise Your right under Section 3(b) of this License
 (right to make Adaptations) but not otherwise.
 
 5. Representations, Warranties and Disclaimer
 
 UNLESS OTHERWISE MUTUALLY AGREED TO BY THE PARTIES IN WRITING, LICENSOR
 OFFERS THE WORK AS-IS AND MAKES NO REPRESENTATIONS OR WARRANTIES OF ANY
 KIND CONCERNING THE WORK, EXPRESS, IMPLIED, STATUTORY OR OTHERWISE,
 INCLUDING, WITHOUT LIMITATION, WARRANTIES OF TITLE, MERCHANTIBILITY,
 FITNESS FOR A PARTICULAR PURPOSE, NONINFRINGEMENT, OR THE ABSENCE OF
 LATENT OR OTHER DEFECTS, ACCURACY, OR THE PRESENCE OF ABSENCE OF ERRORS,
 WHETHER OR NOT DISCOVERABLE. SOME JURISDICTIONS DO NOT ALLOW THE
 EXCLUSION OF IMPLIED WARRANTIES, SO SUCH EXCLUSION MAY NOT APPLY TO YOU.
 
 6. Limitation on Liability. EXCEPT TO THE EXTENT REQUIRED BY APPLICABLE
 LAW, IN NO EVENT WILL LICENSOR BE LIABLE TO YOU ON ANY LEGAL THEORY FOR
 ANY SPECIAL, INCIDENTAL, CONSEQUENTIAL, PUNITIVE OR EXEMPLARY DAMAGES
 ARISING OUT OF THIS LICENSE OR THE USE OF THE WORK, EVEN IF LICENSOR HAS
 BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
 
 7. Termination
 
 a. This License and the rights granted hereunder will terminate
 automatically upon any breach by You of the terms of this License.
 Individuals or entities who have received Adaptations or Collections
 from You under this License, however, will not have their licenses
 terminated provided such individuals or entities remain in full
 compliance with those licenses. Sections 1, 2, 5, 6, 7, and 8 will
 survive any termination of this License.
 
 b. Subject to the above terms and conditions, the license granted here
 is perpetual (for the duration of the applicable copyright in the Work).
 Notwithstanding the above, Licensor reserves the right to release the
 Work under different license terms or to stop distributing the Work at
 any time; provided, however that any such election will not serve to
 withdraw this License (or any other license that has been, or is
 required to be, granted under the terms of this License), and this
 License will continue in full force and effect unless terminated as
 stated above.
 
 8. Miscellaneous
 
 a. Each time You Distribute or Publicly Perform the Work or a
 Collection, the Licensor offers to the recipient a license to the Work
 on the same terms and conditions as the license granted to You under
 this License.
 
 b. Each time You Distribute or Publicly Perform an Adaptation, Licensor
 offers to the recipient a license to the original Work on the same terms
 and conditions as the license granted to You under this License.
 
 c. If any provision of this License is invalid or unenforceable under
 applicable law, it shall not affect the validity or enforceability of
 the remainder of the terms of this License, and without further action
 by the parties to this agreement, such provision shall be reformed to
 the minimum extent necessary to make such provision valid and
 enforceable.
 
 d. No term or provision of this License shall be deemed waived and no
 breach consented to unless such waiver or consent shall be in writing
 and signed by the party to be charged with such waiver or consent. This
 License constitutes the entire agreement between the parties with
 respect to the Work licensed here. There are no understandings,
 agreements or representations with respect to the Work not specified
 here. Licensor shall not be bound by any additional provisions that may
 appear in any communication from You.
 
 e. This License may not be modified without the mutual written agreement
 of the Licensor and You.
 
 f. The rights granted under, and the subject matter referenced, in this
 License were drafted utilizing the terminology of the Berne Convention
 for the Protection of Literary and Artistic Works (as amended on
 September 28, 1979), the Rome Convention of 1961, the WIPO Copyright
 Treaty of 1996, the WIPO Performances and Phonograms Treaty of 1996 and
 the Universal Copyright Convention (as revised on July 24, 1971). These
 rights and subject matter take effect in the relevant jurisdiction in
 which the License terms are sought to be enforced according to the
 corresponding provisions of the implementation of those treaty
 provisions in the applicable national law. If the standard suite of
 rights granted under applicable copyright law includes additional rights
 not granted under this License, such additional rights are deemed to be
 included in the License; this License is not intended to restrict the
 license of any rights under applicable law.
 
 Creative Commons Notice
 
 Creative Commons is not a party to this License, and makes no warranty
 whatsoever in connection with the Work. Creative Commons will not be
 liable to You or any party on any legal theory for any damages
 whatsoever, including without limitation any general, special,
 incidental or consequential damages arising in connection to this
 license. Notwithstanding the foregoing two (2) sentences, if Creative
 Commons has expressly identified itself as the Licensor hereunder, it
 shall have all rights and obligations of Licensor.
 .
 Except for the limited purpose of indicating to the public that the Work
 is licensed under the CCPL, Creative Commons does not authorize the use
 by either party of the trademark "Creative Commons" or any related
 trademark or logo of Creative Commons without the prior written consent
 of Creative Commons. Any permitted use will be in compliance with
 Creative Commons' then-current trademark usage guidelines, as may be
 published on its website or otherwise made available upon request from
 time to time. For the avoidance of doubt, this trademark restriction
 does not form part of this License.
 
 Creative Commons may be contacted at http://creativecommons.org/.
```

### CC0 1.0

[CC0 1.0 Universal](https://creativecommons.org/publicdomain/zero/1.0/)


```
Creative Commons Legal Code

CC0 1.0 Universal

	CREATIVE COMMONS CORPORATION IS NOT A LAW FIRM AND DOES NOT PROVIDE
	LEGAL SERVICES. DISTRIBUTION OF THIS DOCUMENT DOES NOT CREATE AN
	ATTORNEY-CLIENT RELATIONSHIP. CREATIVE COMMONS PROVIDES THIS
	INFORMATION ON AN "AS-IS" BASIS. CREATIVE COMMONS MAKES NO WARRANTIES
	REGARDING THE USE OF THIS DOCUMENT OR THE INFORMATION OR WORKS
	PROVIDED HEREUNDER, AND DISCLAIMS LIABILITY FOR DAMAGES RESULTING FROM
	THE USE OF THIS DOCUMENT OR THE INFORMATION OR WORKS PROVIDED
	HEREUNDER.

Statement of Purpose

The laws of most jurisdictions throughout the world automatically confer
exclusive Copyright and Related Rights (defined below) upon the creator
and subsequent owner(s) (each and all, an "owner") of an original work of
authorship and/or a database (each, a "Work").

Certain owners wish to permanently relinquish those rights to a Work for
the purpose of contributing to a commons of creative, cultural and
scientific works ("Commons") that the public can reliably and without fear
of later claims of infringement build upon, modify, incorporate in other
works, reuse and redistribute as freely as possible in any form whatsoever
and for any purposes, including without limitation commercial purposes.
These owners may contribute to the Commons to promote the ideal of a free
culture and the further production of creative, cultural and scientific
works, or to gain reputation or greater distribution for their Work in
part through the use and efforts of others.

For these and/or other purposes and motivations, and without any
expectation of additional consideration or compensation, the person
associating CC0 with a Work (the "Affirmer"), to the extent that he or she
is an owner of Copyright and Related Rights in the Work, voluntarily
elects to apply CC0 to the Work and publicly distribute the Work under its
terms, with knowledge of his or her Copyright and Related Rights in the
Work and the meaning and intended legal effect of CC0 on those rights.

1. Copyright and Related Rights. A Work made available under CC0 may be
protected by copyright and related or neighboring rights ("Copyright and
Related Rights"). Copyright and Related Rights include, but are not
limited to, the following:

  i. the right to reproduce, adapt, distribute, perform, display,
	 communicate, and translate a Work;
 ii. moral rights retained by the original author(s) and/or performer(s);
iii. publicity and privacy rights pertaining to a person's image or
	 likeness depicted in a Work;
 iv. rights protecting against unfair competition in regards to a Work,
	 subject to the limitations in paragraph 4(a), below;
  v. rights protecting the extraction, dissemination, use and reuse of data
	 in a Work;
 vi. database rights (such as those arising under Directive 96/9/EC of the
	 European Parliament and of the Council of 11 March 1996 on the legal
	 protection of databases, and under any national implementation
	 thereof, including any amended or successor version of such
	 directive); and
vii. other similar, equivalent or corresponding rights throughout the
	 world based on applicable law or treaty, and any national
	 implementations thereof.

2. Waiver. To the greatest extent permitted by, but not in contravention
of, applicable law, Affirmer hereby overtly, fully, permanently,
irrevocably and unconditionally waives, abandons, and surrenders all of
Affirmer's Copyright and Related Rights and associated claims and causes
of action, whether now known or unknown (including existing as well as
future claims and causes of action), in the Work (i) in all territories
worldwide, (ii) for the maximum duration provided by applicable law or
treaty (including future time extensions), (iii) in any current or future
medium and for any number of copies, and (iv) for any purpose whatsoever,
including without limitation commercial, advertising or promotional
purposes (the "Waiver"). Affirmer makes the Waiver for the benefit of each
member of the public at large and to the detriment of Affirmer's heirs and
successors, fully intending that such Waiver shall not be subject to
revocation, rescission, cancellation, termination, or any other legal or
equitable action to disrupt the quiet enjoyment of the Work by the public
as contemplated by Affirmer's express Statement of Purpose.

3. Public License Fallback. Should any part of the Waiver for any reason
be judged legally invalid or ineffective under applicable law, then the
Waiver shall be preserved to the maximum extent permitted taking into
account Affirmer's express Statement of Purpose. In addition, to the
extent the Waiver is so judged Affirmer hereby grants to each affected
person a royalty-free, non transferable, non sublicensable, non exclusive,
irrevocable and unconditional license to exercise Affirmer's Copyright and
Related Rights in the Work (i) in all territories worldwide, (ii) for the
maximum duration provided by applicable law or treaty (including future
time extensions), (iii) in any current or future medium and for any number
of copies, and (iv) for any purpose whatsoever, including without
limitation commercial, advertising or promotional purposes (the
"License"). The License shall be deemed effective as of the date CC0 was
applied by Affirmer to the Work. Should any part of the License for any
reason be judged legally invalid or ineffective under applicable law, such
partial invalidity or ineffectiveness shall not invalidate the remainder
of the License, and in such case Affirmer hereby affirms that he or she
will not (i) exercise any of his or her remaining Copyright and Related
Rights in the Work or (ii) assert any associated claims and causes of
action with respect to the Work, in either case contrary to Affirmer's
express Statement of Purpose.

4. Limitations and Disclaimers.

 a. No trademark or patent rights held by Affirmer are waived, abandoned,
	surrendered, licensed or otherwise affected by this document.
 b. Affirmer offers the Work as-is and makes no representations or
	warranties of any kind concerning the Work, express, implied,
	statutory or otherwise, including without limitation warranties of
	title, merchantability, fitness for a particular purpose, non
	infringement, or the absence of latent or other defects, accuracy, or
	the present or absence of errors, whether or not discoverable, all to
	the greatest extent permissible under applicable law.
 c. Affirmer disclaims responsibility for clearing rights of other persons
	that may apply to the Work or any use thereof, including without
	limitation any person's Copyright and Related Rights in the Work.
	Further, Affirmer disclaims responsibility for obtaining any necessary
	consents, permissions or other rights required for any use of the
	Work.
 d. Affirmer understands and acknowledges that Creative Commons is not a
	party to this document and has no duty or obligation with respect to
	this CC0 or use of the Work.
```


### SIL OPEN FONT LICENSE Version 1.1

[SIL OPEN FONT LICENSE Version 1.1 - 26 February 2007](https://openfontlicense.org/open-font-license-official-text/)
```
PREAMBLE
The goals of the Open Font License (OFL) are to stimulate worldwide
development of collaborative font projects, to support the font creation
efforts of academic and linguistic communities, and to provide a free and
open framework in which fonts may be shared and improved in partnership
with others.

The OFL allows the licensed fonts to be used, studied, modified and
redistributed freely as long as they are not sold by themselves. The
fonts, including any derivative works, can be bundled, embedded,
redistributed and/or sold with any software provided that any reserved
names are not used by derivative works. The fonts and derivatives,
however, cannot be released under any other type of license. The
requirement for fonts to remain under this license does not apply
to any document created using the fonts or their derivatives.

DEFINITIONS
"Font Software" refers to the set of files released by the Copyright
Holder(s) under this license and clearly marked as such. This may
include source files, build scripts and documentation.

"Reserved Font Name" refers to any names specified as such after the
copyright statement(s).

"Original Version" refers to the collection of Font Software components as
distributed by the Copyright Holder(s).

"Modified Version" refers to any derivative made by adding to, deleting,
or substituting -- in part or in whole -- any of the components of the
Original Version, by changing formats or by porting the Font Software to a
new environment.

"Author" refers to any designer, engineer, programmer, technical
writer or other person who contributed to the Font Software.

PERMISSION & CONDITIONS
Permission is hereby granted, free of charge, to any person obtaining
a copy of the Font Software, to use, study, copy, merge, embed, modify,
redistribute, and sell modified and unmodified copies of the Font
Software, subject to the following conditions:

1) Neither the Font Software nor any of its individual components,
in Original or Modified Versions, may be sold by itself.

2) Original or Modified Versions of the Font Software may be bundled,
redistributed and/or sold with any software, provided that each copy
contains the above copyright notice and this license. These can be
included either as stand-alone text files, human-readable headers or
in the appropriate machine-readable metadata fields within text or
binary files as long as those fields can be easily viewed by the user.

3) No Modified Version of the Font Software may use the Reserved Font
Name(s) unless explicit written permission is granted by the corresponding
Copyright Holder. This restriction only applies to the primary font name as
presented to the users.

4) The name(s) of the Copyright Holder(s) or the Author(s) of the Font
Software shall not be used to promote, endorse or advertise any
Modified Version, except to acknowledge the contribution(s) of the
Copyright Holder(s) and the Author(s) or with their explicit written
permission.

5) The Font Software, modified or unmodified, in part or in whole,
must be distributed entirely under this license, and must not be
distributed under any other license. The requirement for fonts to
remain under this license does not apply to any document created
using the Font Software.

TERMINATION
This license becomes null and void if any of the above conditions are
not met.

DISCLAIMER
THE FONT SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT
OF COPYRIGHT, PATENT, TRADEMARK, OR OTHER RIGHT. IN NO EVENT SHALL THE
COPYRIGHT HOLDER BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
INCLUDING ANY GENERAL, SPECIAL, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL
DAMAGES, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF THE USE OR INABILITY TO USE THE FONT SOFTWARE OR FROM
OTHER DEALINGS IN THE FONT SOFTWARE.
```
