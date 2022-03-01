
#ifndef FreqMeasure_capture_h_
#define FreqMeasure_capture_h_

// Arduino Mega
#if defined(__AVR_ATmega1280__) || defined(__AVR_ATmega2560__)
  // #define CAPTURE_USE_TIMER1    // ICP1 is not connected
  // #define CAPTURE_USE_TIMER3    // ICP3 is not connected
  #define CAPTURE_USE_TIMER4       // ICP4 is pin 49
  // #define CAPTURE_USE_TIMER5    // ICP5 is pin 48

#else
  #error "Unknown chip, please edit me with timer+counter definitions"

#endif

#if defined(CAPTURE_USE_TIMER4)

static uint8_t saveTCCR4A, saveTCCR4B;

static inline void capture_init(void)
{
	saveTCCR4A = TCCR4A; // timer 4 register on the arduino mega
	saveTCCR4B = TCCR4B; // timer 4 register on the arduino mega
	TCCR4B = 0;
	TCCR4A = 0;
	TCNT4 = 0;
	TIFR4 = (1<<ICF4) | (1<<TOV4); // TOV is a timer overflow flag, ICF is Input Capture Flag
	TIMSK4 = (1<<ICIE4) | (1<<TOIE4); //ICIE4 an input capture interrupt enable, Timer/Counter0 Overflow Interrupt Enable
}
static inline void capture_start(void)
{
	TCCR4B = (1<<ICNC4) | (1<<ICES4) | (1<<CS40);
}
static inline uint16_t capture_read(void)
{
	return ICR4;
}
static inline uint8_t capture_overflow(void)
{
	return TIFR4 & (1<<TOV4);
}
static inline void capture_overflow_reset(void)
{
	TIFR4 = (1<<TOV4);
}
static inline void capture_shutdown(void)
{
	TCCR4B = 0;
	TIMSK4 = 0;
	TCCR4A = saveTCCR4A;
	TCCR4B = saveTCCR4B;
}

#define TIMER_OVERFLOW_VECTOR  TIMER4_OVF_vect
#define TIMER_CAPTURE_VECTOR   TIMER4_CAPT_vect 

#endif // CAPTURE_USE_***


#endif