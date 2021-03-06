package
{
	import flash.display.*;
	import flash.events.*;
	
	import flash.external.*;
	import flash.system.System;
	
	import mx.controls.SWFLoader;
	import mx.core.*;
	import mx.utils.*;
	import mx.controls.Alert;
	import flash.utils.getTimer; 

	public class Gravity
	{
		public static var view:SWFLoader = FlexGlobals.topLevelApplication.view;
		public static var app:Object = FlexGlobals.topLevelApplication;
		public static var path_data:BitmapData = new BitmapData(3000, 3000, true, 0x00000000);
		public static var path_canvas:Bitmap = new Bitmap(path_data);
		public static var particles:Vector.<Particle> = new Vector.<Particle>;
		public static var h:Number;
		public static var num_particles:Number;
		public static var zero_mass:Number = 1;
		
		public static function init():void
		{	
			FlexGlobals.topLevelApplication.parent.parent.frameRate = 60;
			h=1/200;
			view.addChild(path_canvas);
			view.scaleX = 1;
		}
		
		public static function main():void
		{
			integrate();
			Particle.draw();
			num_particles = particles.length;
			app.particle_quantity.text = "Particles: "+num_particles;
		}
		
		private static function integrate():void
		{
			var new_particles:Vector.<Particle> = new Vector.<Particle>;
			
			for each (var particle:Particle in particles)
			{
				particle.acc_x = 0;
				particle.acc_y = 0;
			}
				
			for each (var other_particle:Particle in particles)
			{
			if( (other_particle.mass > zero_mass) )
				for each (var particle:Particle in particles)
				{
					if (!(particle == other_particle) && !particle.collided && !other_particle.collided)  // prevents computing force with itself. 
																										  // !particle.collided prevents further calculations for any previously collided particles. This is necessary to not create multiple particles for a single collision event which causes a collision chain reaction of new particles.
																										  // !other_particle.collided is the other side of the coin, making sure the particle being compared against has not already collided.
					{								   
						var x_diff:Number = (other_particle.pos_x - particle.pos_x);
						var y_diff:Number = (other_particle.pos_y - particle.pos_y);
						var displacement_magnitude:Number = Math.sqrt(x_diff*x_diff + y_diff*y_diff)
						
						if( particle.mass > zero_mass )
						if (displacement_magnitude < particle.radius/1.5 + other_particle.radius/1.5)
						{
							particle.collided = true;
							other_particle.collided = true;
							
							var sum_mass:Number = particle.mass + other_particle.mass;
							var new_particle:Particle = new Particle (particle.mass + other_particle.mass,
																	 (particle.vel_x*particle.mass + other_particle.vel_x*other_particle.mass) / sum_mass,
																	 (particle.vel_y*particle.mass + other_particle.vel_y*other_particle.mass) / sum_mass,
																	 (particle.pos_x*particle.mass + other_particle.pos_x*other_particle.mass) / sum_mass,
																	 (particle.pos_y*particle.mass + other_particle.pos_y*other_particle.mass) / sum_mass)
							new_particles.push(new_particle);
						}

						var acceleration:Number = other_particle.mass/(displacement_magnitude*displacement_magnitude);
						particle.acc_x += acceleration*(x_diff/displacement_magnitude);
						particle.acc_y += acceleration*(y_diff/displacement_magnitude);
					}
				}
			}
			
			for each (var particle:Particle in particles)
			{
				if(Interface.virtual_mass_flag>0) {
					var x_diff:Number = (Interface.virtual_mass_x - particle.pos_x);
					var y_diff:Number = (Interface.virtual_mass_y - particle.pos_y);
					var displacement_magnitude:Number = Math.sqrt(x_diff*x_diff + y_diff*y_diff);
					var acceleration:Number = Interface.virtual_mass/(displacement_magnitude*displacement_magnitude);
					if(displacement_magnitude>5)
					if(displacement_magnitude < Interface.virtual_radius) {
						particle.acc_x += acceleration*(x_diff/displacement_magnitude);
						particle.acc_y += acceleration*(y_diff/displacement_magnitude);
					}
				}
			}
			
			for (var i:Number = 0; i < Gravity.particles.length; i++)
			{
				Gravity.particles[i].vel_x += Gravity.particles[i].acc_x*h;
				Gravity.particles[i].vel_y += Gravity.particles[i].acc_y*h;
				Gravity.particles[i].pos_x += Gravity.particles[i].vel_x*h;
				Gravity.particles[i].pos_y += Gravity.particles[i].vel_y*h;
				if (Gravity.particles[i].collided)
				{
					Gravity.view.removeChild(Gravity.particles[i]);
					Gravity.particles.splice(i,1);
					i-- // Backtracks the index, otherwise the effect of splicing (causing index values of all items beyond splice range to shift down) would cause the next item to be skipped over.
				}
			}
			
			var central_body_indx:Number = 0;
			if(Gravity.app.rounding.selected) {
				for (var i:Number = 1; i < Gravity.particles.length; i++) {
					if(Gravity.particles[i].mass >  Gravity.particles[central_body_indx].mass) {
						central_body_indx = i;
					}
				}
				for (var i:Number = 0; i < Gravity.particles.length; i++) {
					var xvector:Number = Gravity.particles[i].pos_x - Gravity.particles[central_body_indx].pos_x;
					var yvector:Number = Gravity.particles[i].pos_y - Gravity.particles[central_body_indx].pos_y;
					var vectorLen:Number = Math.sqrt(xvector*xvector + yvector*yvector);
					if(vectorLen>0) {
						xvector /= vectorLen;
						yvector /= vectorLen;
					}
					var scalar:Number = Gravity.particles[i].vel_x*xvector + Gravity.particles[i].vel_y*yvector;
					Gravity.particles[i].vel_x -= xvector*scalar/100;
					Gravity.particles[i].vel_y -= yvector*scalar/100;
				}
			}

			for each (var new_particle:Particle in new_particles)
			{
				particles.push(new_particle);
				view.addChild(new_particle);
			}
		}
	}
}