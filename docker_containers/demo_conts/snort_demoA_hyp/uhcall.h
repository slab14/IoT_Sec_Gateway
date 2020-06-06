/*
 * @UBERXMHF_LICENSE_HEADER_START@
 *
 * uber eXtensible Micro-Hypervisor Framework (Raspberry Pi)
 *
 * Copyright 2018 Carnegie Mellon University. All Rights Reserved.
 *
 * NO WARRANTY. THIS CARNEGIE MELLON UNIVERSITY AND SOFTWARE ENGINEERING
 * INSTITUTE MATERIAL IS FURNISHED ON AN "AS-IS" BASIS. CARNEGIE MELLON
 * UNIVERSITY MAKES NO WARRANTIES OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
 * AS TO ANY MATTER INCLUDING, BUT NOT LIMITED TO, WARRANTY OF FITNESS FOR
 * PURPOSE OR MERCHANTABILITY, EXCLUSIVITY, OR RESULTS OBTAINED FROM USE OF
 * THE MATERIAL. CARNEGIE MELLON UNIVERSITY DOES NOT MAKE ANY WARRANTY OF
 * ANY KIND WITH RESPECT TO FREEDOM FROM PATENT, TRADEMARK, OR COPYRIGHT
 * INFRINGEMENT.
 *
 * Released under a BSD (SEI)-style license, please see LICENSE or
 * contact permission@sei.cmu.edu for full terms.
 *
 * [DISTRIBUTION STATEMENT A] This material has been approved for public
 * release and unlimited distribution.  Please see Copyright notice for
 * non-US Government use and distribution.
 *
 * Carnegie Mellon is registered in the U.S. Patent and Trademark Office by
 * Carnegie Mellon University.
 *
 * @UBERXMHF_LICENSE_HEADER_END@
 */

/*
 * Author: Amit Vasudevan (amitvasudevan@acm.org)
 *
 */

/*
	libuhcall header

	author: amit vasudevan (amitvasudevan@acm.org)
*/

#ifndef __UHCALL_H__
#define __UHCALL_H__

#define UHCALL_PM_PAGE_SHIFT 	12
#define UHCALL_PM_PAGE_SIZE	4096
#define UHCALL_PM_LENGTH	8


#ifndef __ASSEMBLY__

typedef struct {
	unsigned long uhcall_function;
	void *uhcall_buffer;
	unsigned long uhcall_buffer_len;
} uhcallkmod_param_t;


bool uhcall_va2pa(void *vaddr, uint64_t *paddr);
bool uhcall(uint32_t uhcall_function, void *uhcall_buffer, uint32_t uhcall_buffer_len);


#endif // __ASSEMBLY__



#endif //__UHCALL_H__
