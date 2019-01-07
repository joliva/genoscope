// --------------------------------------------------------------------
include <Helix/helix_extrude.scad>

/* [Mode] */

// Object View 
VIEW = "genoled";   // ["genoled", "rung_jig", "helix_jig", "datacon_jig"]

/* [Ignore] */
FN = 32;

AWG20 = 0.95;
AWG8 = 4.366;

// Helix
RADIUS = 60;
HEIGHT = 150;
THICKNESS = AWG8;
NUM_TWISTS = 6;
LEVELS = NUM_TWISTS;
VERT_INTERVAL = HEIGHT/LEVELS;
NUM_HELIX = 1;
deg = 360.0/NUM_HELIX;
HL = NUM_TWISTS * sqrt(pow(HEIGHT,2) + pow(2*PI*RADIUS,2));

// LED rung
LED_DIAM = 10;
LED_THICK = 3;
INTER_LED_DIST = 25.0;
NUM_LEDS_RUNG = 4;
NUM_LEDS_RUNG_EVEN = (NUM_LEDS_RUNG/2==floor(NUM_LEDS_RUNG/2));
DIST_END_LEDS = (NUM_LEDS_RUNG-1)*INTER_LED_DIST;
HORIZ_ALL_LED = DIST_END_LEDS + LED_DIAM;
DIST_TO_HELIX = (2*RADIUS - HORIZ_ALL_LED)/2;
PER_LED_CURRENT = 60;
DATA_OFFSET_Y = 3;

colors = ["red","black","blue","green", "yellow", "orange", "pink", "purple"];

echo(str("Height: ", HEIGHT, " mm", "   Radius: ", RADIUS, " mm"));
echo(str("Number of LED rungs: ", LEVELS));
echo(str("Distance between rungs: ", VERT_INTERVAL, " mm"));
echo(str("Length of helix + base ext: ", HL + 2*PI*RADIUS*((300+182)/360), " mm"));
echo(str("Max LED Power: ", NUM_LEDS_RUNG*LEVELS*PER_LED_CURRENT, " ma @ 5V"));
// --------------------------------------------------------------------

// --------------------------------------------------------------------
module nodemcu() {
    color("DarkSlateGrey")
    rotate([0,0,-90])
    import("nodemcu.stl");
}
// --------------------------------------------------------------------

// --------------------------------------------------------------------
module LED (d_led) {
    cols = ["red", "blue", "black"];
    
    color("white")
    cylinder(d=d_led, h=LED_THICK, center=true, $fn=FN);
    
    for (i=[0:2]) {
        color(cols[i])
        translate([1.3*(i-1)*d_led/7,1.5*d_led/7,-LED_THICK/2])
            cube([1, 2*d_led/7, .1], center=true);

        color(cols[i])
        translate([1.3*(i-1)*d_led/7,-1.5*d_led/7,-LED_THICK/2])
            cube([1, 2*d_led/7, .1], center=true);
    }
}
// --------------------------------------------------------------------

// --------------------------------------------------------------------
module rung(r_wire, d_led, , h, rot, trans, level_even, topflag) {
    new_rot = [rot.x, rot.y + (level_even ? 0 : 180), rot.z];
    
    translate(trans)
    rotate(new_rot) {
        color("SandyBrown") {
            for (i=[1:NUM_LEDS_RUNG-1]) {
                translate([VERT_INTERVAL,r_wire,-DIST_END_LEDS/2+(i-.5)*INTER_LED_DIST])
                    cylinder(r=r_wire, h=INTER_LED_DIST-4, center=true, $fn=FN);
            }
            
            // positive LED power (horizontal)
            translate([VERT_INTERVAL+1.8,r_wire,0])
                cylinder(r=r_wire, h=DIST_END_LEDS-4, center=true, $fn=FN);
             
            // negative LED power (horiztontal)
            translate([VERT_INTERVAL-1.8,r_wire,0])
                cylinder(r=r_wire, h=2*(RADIUS-AWG8), center=true, $fn=FN);
        }
        
        for (i=[0:NUM_LEDS_RUNG-1]) {
            translate([0,-LED_THICK/2,-DIST_END_LEDS/2 + i*INTER_LED_DIST])
            rotate([90,0,0])
            LED(d_led=d_led);
        }
    }
}
// --------------------------------------------------------------------

// --------------------------------------------------------------------
module helix(radius, twists, height, thick) {
    helix_extrude(angle=twists*360, height=height, $fn=FN) {
        translate([radius, 0, 0]) {
            circle(d=thick);
        }
    }
}
// --------------------------------------------------------------------

// --------------------------------------------------------------------
module helices(num_helix, radius, twists, height, thick) {
    dtheta = 360/num_helix;

    color("SandyBrown")
    union() {
        for (i=[0:num_helix-1]) {
            rotate([0,0,i*dtheta])
            helix(radius, twists, height, thick);
        }
    }
}
// --------------------------------------------------------------------

// --------------------------------------------------------------------
module inter_rung(r_wire, d_led=LED_DIAM, , h, off_y, trans, level_even) {
    color("SandyBrown")
    translate(trans) {
        // vertical
        cylinder(r=r_wire, h=h, center=true, $fn=FN);
        
        // connect vertical to leg on pin
        
        translate([0,-off_y/2, h/2])
        rotate([90,0,0])
        cylinder(r=r_wire, h=off_y, center=true, $fn=FN);
 
        translate([0,-off_y/2, -h/2])
        rotate([90,0,0])
        cylinder(r=r_wire, h=off_y, center=true, $fn=FN);
        
        // leg connected to pin
        
        translate([level_even ? -1 : 1,-off_y+r_wire, h/2])
        rotate([0,90,0])
        cylinder(r=r_wire, h=3, center=true, $fn=FN);
        
        translate([level_even ? -1 : 1,-off_y+r_wire, -h/2])
        rotate([0,90,0])
        cylinder(r=r_wire, h=3, center=true, $fn=FN);
    }
}
// --------------------------------------------------------------------

module genoled() {
    helices(num_helix=NUM_HELIX, radius=RADIUS, twists=NUM_TWISTS, height=HEIGHT, thick=THICKNESS);

    color("SandyBrown") {
        // extend helix for a stable base & top
        rotate_extrude(angle=-300, $fn=FN) {
            translate([RADIUS, 0, 0])
                circle(d=THICKNESS);
        }
        
        rotate([0,0,180])
        translate([0,0,HEIGHT])
        rotate_extrude(angle=182, $fn=FN) {
            translate([-RADIUS, 0, 0])
                circle(d=THICKNESS);
        }
        
        // verticals along helix
        translate([-RADIUS+THICKNESS, 0, HEIGHT/2])
        cylinder(d=THICKNESS, h=HEIGHT, center=true, $fn=FN);
 
        translate([RADIUS-THICKNESS, 0, HEIGHT/2])
        cylinder(d=THICKNESS, h=HEIGHT, center=true, $fn=FN); 
    }

    for (i=[1:LEVELS]) {
        level_even = (i/2==floor(i/2));
        x1 = level_even ? DIST_END_LEDS/2 + 3: -DIST_END_LEDS/2 - 3;
        x2 = level_even ? DIST_END_LEDS/2 + 1: -DIST_END_LEDS/2 - 1;

        rung(r_wire=AWG20, d_led=LED_DIAM, AWG20/2, h=2*RADIUS, rot=[0,90,0], trans=[0,0,i*VERT_INTERVAL], level_even=level_even, topflag=(i==LEVELS));
        
        // data connection (vertical)
        inter_rung(r_wire=AWG20, d_led=LED_DIAM, AWG20/2, h=VERT_INTERVAL, off_y=DATA_OFFSET_Y, trans=[x1,DATA_OFFSET_Y,(i-1)*VERT_INTERVAL + VERT_INTERVAL/2], level_even=level_even);
        
        // power connection (vertical)
        inter_rung(r_wire=AWG20, d_led=LED_DIAM, AWG20/2, h=VERT_INTERVAL+(level_even ? 2*1.8 : -2*1.8), off_y=DATA_OFFSET_Y, trans=[-x2,DATA_OFFSET_Y,(i-1)*VERT_INTERVAL + VERT_INTERVAL/2], level_even=level_even);
    }
}

if (VIEW == "genoled") {
    genoled();
    nodemcu();
} else if (VIEW == "rung_jig") {
    THK = LED_THICK+4;
    HT = HEIGHT/2;
    CLR_LED = 0.7;
    CLR_WIRE = 0.3;
    
    difference() {
        translate([0,-THK/2-.001,HT/2+3*VERT_INTERVAL/2])
            cube([2*RADIUS+10, THK, HT], center=true);
        
        for (i=[1:LEVELS]) {
            level_even = (i/2==floor(i/2));
            x = level_even ? DIST_END_LEDS/2 + 3: -DIST_END_LEDS/2 - 3;

            rung(r_wire=AWG20, d_led=LED_DIAM+CLR_LED, AWG20/2, h=2*RADIUS, rot=[0,90,0], trans=[0,0,i*VERT_INTERVAL], level_even=level_even, topflag=(i==LEVELS));
            translate([0,-0.7,0])
            rung(r_wire=AWG20, d_led=LED_DIAM+CLR_LED, AWG20/2+CLR_WIRE, h=2*RADIUS, rot=[0,90,0], trans=[0,0,i*VERT_INTERVAL], level_even=level_even, topflag=(i==LEVELS));
        }
        
        helices(num_helix=NUM_HELIX, radius=RADIUS, twists=NUM_TWISTS, height=HEIGHT, thick=THICKNESS);
    }
} else if (VIEW == "helix_jig") {
    CLR_WIRE = 0.5;
    
    difference() {
        translate([0,0,HEIGHT/2])
            cylinder(r=RADIUS, h=HEIGHT+15, $fn=2*FN, center=true);
 
        translate([0,0,-15/2-.01])
            cylinder(r=RADIUS-10, h=5, $fn=2*FN, center=true);

        // Thickness = 4.4 for integral # of perimeters
        translate([0,0,HEIGHT/2+5/2-.1])
            cylinder(r=RADIUS-4.4, h=HEIGHT+15, $fn=2*FN, center=true);
       
        helices(num_helix=NUM_HELIX, radius=RADIUS, twists=NUM_TWISTS, height=HEIGHT, thick=THICKNESS+CLR_WIRE);

        // extend helices for a stable base
        color("SandyBrown") {
            rotate_extrude(angle=-135, $fn=FN) {
                translate([RADIUS, 0, 0])
                    circle(d=THICKNESS+CLR_WIRE);
            }

            rotate_extrude(angle=-135, $fn=FN) {
                translate([-RADIUS, 0, 0])
                    circle(d=THICKNESS+CLR_WIRE);
            }
        }
    }  
} else if (VIEW == "datacon_jig") {
    CLR_WIRE = 0.5;
    BASE_H = 8;  BASE_W = VERT_INTERVAL+2*10;  BASE_D = 38;
    END_H = 2;  END_D = AWG20+CLR_WIRE;
    OFFSET_H = 5;  OFFSET_W = VERT_INTERVAL;  OFFSET_D = 2*DATA_OFFSET_Y;

//1.3*LED_DIAM/7
    
    difference() {
        union() {
            // base
            translate([0,0,BASE_H/2])
                cube([BASE_W,BASE_D,BASE_H], center=true);
            
            translate([0,-(OFFSET_D+2),0]) {
                for (i=[0:2]) {
                    // offset + vertical
                    translate([0,i*(OFFSET_D+2),BASE_H + OFFSET_H/2])
                        cube([OFFSET_W+(i-1)*LED_DIAM*1.3/7,OFFSET_D,OFFSET_H], center=true);
                }
            }
        }
            
       translate([0,-(OFFSET_D+2),0]) {
            for (i=[0:2]) {
                // contact ends
                translate([-VERT_INTERVAL/2-END_D/2-(i-1)*LED_DIAM*1.3/14,i*(OFFSET_D+2),BASE_H-END_H/2+.001])
                    cylinder(d=END_D, h=END_H, $fn=FN, center=true);
                translate([VERT_INTERVAL/2+END_D/2+(i-1)*LED_DIAM*1.3/14,i*(OFFSET_D+2),BASE_H-END_H/2+.001])
                    cylinder(d=END_D, h=END_H, $fn=FN, center=true);
            }
        }
    }
}
