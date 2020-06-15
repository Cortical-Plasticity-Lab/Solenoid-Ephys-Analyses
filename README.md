# Solenoid Analyses
Analyses for multi-unit spiking responses &amp; evoked local field potentials (LFP) obtained in response to mechanical stimulation of the forelimb digits ("Solenoid"), intracortical microstimulation (ICMS), or Solenoid+ICMS stimuli from the anesthetized rat. 

* Start with `main.m`
* Organization of objects is hierarchical:
  * `solBlock` is "child" to `solRat`
  * `solChannel` is "child" to `solBlock`
  * Constructor for `solRat` automatically generates all subordinate `solBlock` and `solChannel` objects, so the main access-point in general for batch analysis is `solRat`, while methods at `solBlock` level are more for trouble-shooting and testing or development.
* Once all `solRat` objects are constructed, they can be saved using the overloaded `save` method of `solRat`.
* Once batch figures are exported (also requires connection to KUMC Isilon Processed_Data drives), the exported figures can be viewed using the `figBrowser` class, which is primarily convenient if you need to re-export higher resolution versions of existing figures.
## To-Do ##

* Determine if there is usable data to test the following generic hypothesis:
  * ICMS induces functional changes in somatosensory evoked potentials.
* To test this hypothesis, we should examine these sub-hypotheses:
  * ICMS induces a **statistically significant** change in _**duration**_ between **_first_ evoked multi-unit spike peak** and cutaneous stimulus offset, compared to responses during cutaneous stimulation _only_.
  * ICMS induces a **statistically significant** change in _**magnitude**_ of **average evoked LFP response** when paired with cutaneous stimuli.
* To bring these hypotheses into _clinical relevance_, we should test the following hypotheses:
  * ICMS in **RFA** (which is where most of the stimuli were targeted) alters evoked responses (spiking, LFP, or linear/nonlinear metrics of information transfer between the two areas in response to cutaneous stimulus) in **FL-S1**.