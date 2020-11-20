# Solenoid Evoked Spiking #

## General Approach ##

### First Attempt ###

Initially, I tried using the following model:

Counts of spike peaks in windows following either Solenoid or ICMS stimulus. Binomial GLME with logit link function was fit for different responses defined by windows and stimulus response (4 different models) with the following general structure:

`"# peaks" ~ 1 + Type*Volume*Area + (1 | Block) `

* Type: [Solenoid or ICMS] or Solenoid + ICMS
* Area: RFA or S1
* Volume: Lesion volume (continuous value)
* Block: Identifier for recording session. 

Because `Block` is more granular than `Rat`, the latter was not included in the model. Each recording site has a unique `Channel` identifier; however, because `Channel` is more granular than `Area` and we wanted to test differences by `Area`, we did not include a term for `Channel` in the model. This is because the peak determination depends on cross-trial averages by `Type` within a `Block`; therefore, individual samples are `Channels`. 

The Binomial Size parameter was determined by the maximum total number of peaks within 5-to-500 milliseconds of the stimulus with alignment to stimuli of either `Type`. 

### Improved Model ###

Upon evaluating the distribution of residuals generated in the first model conception, I realized there were some problems. I was concerned about the apparent discrete trends that I at first couldn't associate to any evident model parameter since they didn't match up even when I named them using model terms and looked at the individual data points. Fortunately, I realized that this was actually due to a combination of data features and not a single model term per se; plotting the scatter by the "joint" input distribution incorporating `BinomialSize` parameter gives intuition about why these discrete trends form (**[Figure R1](#figure-r1)**). 

At that point, we have to think about what the model is telling us. Clearly our data is really biased by having all these entries with no responses. Having apparently correlated trends in residuals is also troubling. 

## Interpreting Model Results ##

**Models**

1. [**Early Solenoid Model**](#early-solenoid-model)
2. [**Late Solenoid Model**](#late-solenoid-model)
3. [**Early ICMS Model**](#early-icms-model)
4. [**Late ICMS Model**](#late-icms-model)

---

### Solenoid Models ###

There were 1,408 observations (unique combinations of **`Block`**, **`Channel`**, and **`Type`**), with 422 observations excluded due to not meeting the evoked peak criterion. A **`peak`** required a cross-trial expectation equal or exceeding the average pre-stimulus spike rate plus three times its standard deviation. The top-5 **`peaks`** were collected from the 0.5 second epoch after the stimulus according to their amplitudes (the total number of expected spikes in a 2.5 millisecond "bin"). The 422 excluded observations refer to channels with no such peaks within either the "**[Early](#early-solenoid-model)**" or "**[Late](#late-solenoid-model)**" windows during which evoked activity was physiologically expected, as defined below.

#### Early Solenoid Model ####

Spike peaks were counted to determine how many occurred during the interval [15, 45) milliseconds following the onset of Solenoid stimulation. This window was selected due to the biophysically plausible timing of afferent pathways related to the sensory fields particularly of S1 that have been studied previously in the rat (e.g. *Moxon studies*). These timings were empirically tested in pilot rats (not reported) and are also supported by prior literature reporting the expected conduction velocities of the putatively recruited pathways (*which are **X***). 

![Solenoid-Early-Residuals](D:\MATLAB\Projects\Solenoid-Ephys-Analyses\figures\reports\Solenoid-Early-Residuals.png)

![Solenoid-Early-Residuals-Fitted](D:\MATLAB\Projects\Solenoid-Ephys-Analyses\figures\reports\Solenoid-Early-Residuals-Fitted.png)![Solenoid-Early-Input-Distribution](D:\MATLAB\Projects\Solenoid-Ephys-Analyses\figures\reports\Solenoid-Early-Input-Distribution.png)

##### Figure R1 ##### 

**Histogram of residuals and scatter of fitted residuals for the Early Peak Solenoid model.** *(Top) The distribution of residuals is clumped up near zero and then over-dispersed, so it doesn't look like this is the greatest of fits. (Middle) When the residuals are plotted against their fitted values, we see that it breaks down into 10-11 discrete trends. (Bottom) What do those trends correspond to? When we look at the input distribution as a joint distribution, combining information about the **`BinomialSize`** parameter for the binomial GLME fitting procedure as well as the response distribution (here, the number of peaks in the Early window in response to Solenoid), we can see that there are roughly 10-11 joint combinations (jitter was added to integer values for visualization only) with a substantial number of points present. So this is what is causing it to look "funky".*  

#### Late Solenoid Model ####

Spike peaks were counted to determine how many occurred during the interval [90,300) milliseconds following the onset of Solenoid stimulation. These spikes could manifest via probably several different mechanisms, but the simplest explanator could be conceived as a "rebound" from the hyperpolarized membrane state following inhibition. If the cell membrane voltage is artificially hyperpolarized (e.g. due to GABA-mediated synaptic inhibition), the Nernst potentials of the other ionic channels change. Accordingly, as the cell is released from its hyperpolarized state, there is a slightly increased likelihood of observing spiking due to the altered thresholds for recruitment of the voltage-gated sodium channels that lead to the sharp "spike" associated with a neuron's action potential. This probabilistic increase would account for the "broad" timescale of the secondary peak by comparison to the relatively "sharp" timescale of the first. Its ubiquity also supports a mechanism that targets many cells relatively simultaneously, such as inhibition mediated by networks of interneurons. It is possible that this could be related to a biophysical entrainment via the extracellular field potentials resulting in a similar probabilistic "rebound" effect, some combination of these effects, or other unknown phenomena. However, it is most likely that these phenomena exert their influence in generating this peak in some similar manner as described in the first case relating to the hyperpolarized membrane state.

### ICMS Models ###

#### Early ICMS Model ####



#### Late ICMS Model ####

