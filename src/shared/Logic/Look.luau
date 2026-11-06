--!strict
-- Camera geometry with plain numbers (no Vector3, so the Lune specs run it as is). Angles in radians. A view is a
-- position, a yaw and a pitch with Roblox's conventions: yaw 0 looks toward -Z, CFrame.Angles(0, yaw, 0) *
-- CFrame.Angles(pitch, 0, 0) gives the same frame, a negative pitch looks down.
local Look = {}

export type View = {
	x: number,
	y: number,
	z: number,
	yaw: number,
	pitch: number,
	hfov: number, -- full horizontal angle, radians
	vfov: number, -- full vertical angle, radians
	range: number,
}

-- the yaw and pitch that look from (x, y, z) at (tx, ty, tz)
function Look.toward(x: number, y: number, z: number, tx: number, ty: number, tz: number): (number, number)
	local dx, dy, dz = tx - x, ty - y, tz - z
	local flat = math.sqrt(dx * dx + dz * dz)
	return math.atan2(-dx, -dz), math.atan2(dy, flat)
end

-- the unit look direction of a yaw and pitch
function Look.dir(yaw: number, pitch: number): (number, number, number)
	local cp = math.cos(pitch)
	return -math.sin(yaw) * cp, math.sin(pitch), -math.cos(yaw) * cp
end

function Look.view(
	x: number,
	y: number,
	z: number,
	yaw: number,
	pitch: number,
	hfovDeg: number,
	vfovDeg: number,
	range: number
): View
	return {
		x = x,
		y = y,
		z = z,
		yaw = yaw,
		pitch = pitch,
		hfov = math.rad(hfovDeg),
		vfov = math.rad(vfovDeg),
		range = range,
	}
end

-- Is the point inside the view's frustum (range included)? Works in the camera's own axes: right, up and look.
function Look.contains(v: View, px: number, py: number, pz: number): boolean
	local dx, dy, dz = px - v.x, py - v.y, pz - v.z
	if dx * dx + dy * dy + dz * dz > v.range * v.range then
		return false
	end
	local sy, cy = math.sin(v.yaw), math.cos(v.yaw)
	local sp, cp = math.sin(v.pitch), math.cos(v.pitch)
	-- right = (cos y, 0, -sin y); up = (sin y sin p, cos p, cos y sin p); look = (-sin y cos p, sin p, -cos y cos p)
	local f = -sy * cp * dx + sp * dy - cy * cp * dz
	if f <= 1e-6 then
		return false
	end
	local r = cy * dx - sy * dz
	local u = sy * sp * dx + cp * dy + cy * sp * dz
	return math.abs(math.atan2(r, f)) <= v.hfov / 2 and math.abs(math.atan2(u, f)) <= v.vfov / 2
end

-- the smallest signed difference a - b between two angles, in (-pi, pi]
function Look.angleDiff(a: number, b: number): number
	local d = (a - b) % (2 * math.pi)
	if d > math.pi then
		d -= 2 * math.pi
	end
	return d
end

return Look
